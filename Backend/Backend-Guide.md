# Backend Guide

This guide is for the folks out there working on the Backend. You'll probably need to read this before doing anything.
Don't worry, it's not scary lol, just some explanations and what you should know.

Alright, enough pep talk, let's go to the main topic!

## Directory Structure

First, let's take a quick look at the `Backend/` directory, shall we?

```
+ Backend/
+--+ core/ : Core working folder for the Backend, so don't modify it pls.
+--+ data/ : The data folder for the backend, contains configs, logs, and other static data.
|  +--+ configs/ : The configs folder, here's where the config file will be stored.
|  |  +--+ general.json : The general configuration file.
|  +--+ logs/ : The logs folder, here's where the log files will be stored.
+--+ middleware/ : The middleware modules, provide middleware services for the backend.
|  +--+ auth.py : Authentication middleware.
|  +--+ rate_limit.py : Access rate limit middleware.
+--+ routers/ : This is where you put your routes and routers.
+--+ schemas/ : And this is where you put backend models/schemas. Note: Do not use core schemas directly.
+--+ .env : This is your environment variables file. You won't find this on GitHub because you **DON'T PUSH IT TO GITHUB**.
+--+ app.py : This is the backend main entry point.
+--+ query.py : This is the Query System module.
+--+ requirements.txt : Python package requirements file for the backend.
+--+ utils.py : And finally, this is a shared utility file between Core and Backend.
```

So what you're seeing is a backend template for FastAPI. Using a template helps keep your code organized from the beginning, so there's no need to "refactor after a mess" lol.

Alright, now let's dive deeper into each part. We'll approach it in a top-down manner.

---

## Entry Point: `app.py`

Let's start from the entry point `app.py`.

It can be split into 3 main parts: **Lifespan**, **Configuration**, and **Error Handlers** (ignoring the imports at the top).

For you, the one working on the Backend, you only need to know the first two (a.k.a. ignore the Error Handlers).

### 1. The Lifespan

There are 3 functions for this part: `onInitialize`, `onDeinitialize`, and `appLifespan`. You only need to care about the first two; you can leave `appLifespan` as it is—no need to touch it.

`onInitialize() -> bool` is called to initialize the backend before startup. By default, it looks like this:

```python
async def onInitialize() -> bool:
    dotenv.load_dotenv(".env") # Load the '.env' file to the environment variables.

    # Here we'll initialize Config and Logger.
    if not Config.Initialize():
        return False
    Logger.Initialize()

    # Here's where you put the other initialize part...
```

If initialization fails, simply throw an exception or return `False`. That's it.

`onDeinitialize()` is called to free up resources and deinitialize before stopping. By default, it's empty:

```python
async def onDeinitialize():
    # Put your deinitialize logic here, if you need to free, save, or do stuff before stopping...
    pass
```

### 2. The Configuration

Next up is the FastAPI application configuration. Note: this is just for FastAPI, not the general backend config.

This part should be kept simple and clean since it's put outside of the function scope. Let's take a quick look:

```python
# Create the apps
app = FastAPI(lifespan=appLifespan)

# Routers include here
app.include_router(routers.maps.router) # Like this includes the maps API router.
# Note: To include, just call app.include_router(your APIRouter) here.

# Some other configuration here
app.state.limiter = limiter # Like this registers the app state limiter

# Here's the CORS middleware part, for now we don't need to touch it.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Left as intended.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)
```

### 3. The Error Handlers

Down there, you'll see a ton of error handler functions with the `@app.exception_handler(...)` decorator. It looks scary, but you don't need to touch it. Its job is to detect when the server raises an uncaught exception (e.g., `HTTPException`) and respond to the user in a proper format (which we'll talk about later).

Here's an example. Let's say we have a route that throws an unhandled error like this:

```python
# Define some route
@app.get("/error_test")
def error_test():
    raise ValueError("Raise Value Error exception")

@app.get("/http_error_test")
def http_error_test():
    raise HTTPException(status=404, detail="Raise 404 HTTP exception")
```

Now let's say a user calls route `/error_test` and `/http_error_test`. An exception will occur!
But instead of just responding with plain text (FastAPI default), it'll automatically convert it into a proper schema and return it.

For `/error_test` (note that for native exceptions, it'll use HTTP Code 500 - Internal Server Error):
```json
{
    "status" : "error",
    "result" : "error",
    "data" : [
        {
            "code" : 500,
            "detail" : "ValueError: Raise Value Error exception"
        }
    ]
}
```

And for `/http_error_test`:
```json
{
    "status" : "error",
    "result" : "error",
    "data" : [
        {
            "code" : 404,
            "detail" : "Raise 404 HTTP exception"
        }
    ]
}
```

It also automatically reformats and handles Validation errors and Rate limit errors.

So yeah, you don't need to manually catch and handle failed exceptions.
A common practice in routers is: if something fails, raise an `HTTPException`. Or, catch a native error, wrap it, and rethrow it as an `HTTPException` for more details.

```python
@app.get("/get_user")
def get_user(username: str):
    result = query_user(username)
    if result is None: # Not found user
        raise HTTPException(status=404, detail=f"User with username '{username}' is not found!")
    return ObjectResponseSchema(data=result) # We'll talk about this later on, just assuming we return this.
```

---

## Routers, Schemas, and Middleware

Alright, next, let's talk about the `routers`, `schemas`, and `middleware` modules. Let's take a look at `routers/maps.py`, shall we?

### 1. Routers and Routes

To create a route, first put it inside a category. This helps detach and distinguish between routes.
In `routers/maps.py`, the category is `maps`. A typical way to do this is to create an `APIRouter` to define a category.

```python
router = APIRouter(prefix="/<route_prefix>", tags=["<Category name>"])
```

Like in `routers/maps.py`, a router is defined as:
```python
router = APIRouter(prefix="/maps", tags=["Maps Informations"]) 
```

This creates an API router. All routes under this router will have the `/maps` prefix (e.g., `/maps/search`, `/maps/place`,...), and in the API docs, it's put under the `Maps Informations` category.

Next, how do we actually define a route? Well, if you have some experience with FastAPI, you know that we can use the `@router.get`, `@router.post`, `@router.put`,... decorators.

Usually for this project, we'll only need to use the HTTP `GET` method. Now, `maps.py` has really—and I mean *really*—huge and scary-looking functions, especially if you're new! But to be honest, it's way easier than you think, lol!

Here's how to create a route (notice that since we're using FastAPI, most functions should be `async`):

```python
@router.get( # Create a GET route 
    "/<prefix_format>", # The prefix format for the route, it can also accept parameterized formats!
                        # For example (with router having prefix "/maps"):
                        #   - "/search" -> Only accepts /maps/search
                        #   - "/{ids}/info -> Accepts all with correct format like /maps/123/info, /maps/abc/info,...
    name="<Route Name>",    # The route name to display in the API docs
    status_code=<http_code>,# Successful status code to return
                            # Usually 200 (OK), you can take a look at module fastapi.status to see known statuses.
    response_model=<PydanticModel>, # The Pydantic model of the response, on success
                                    # It's recommended to use predefined models/schemas template for response, which are:
                                    #   - ObjectResponseModel[<ReturnT>] : If you only return a single object
                                    #   - CollectionResponseModel[<ReturnT>] : If you return multiple objects of the same type
                                    #   - MessageResponseModel[<ReturnT>] : If you return a message (e.g. status message)
                                    # I'll talk about the standard predefined schemas/models template later
    description="<Route description>",  # The description of the route (to show in the API docs)
    responses={
        <error_code>={ "model" : ErrorResponseSchema }
        # You'll list the "possible" other response formats beside the successful one here, usually it's all error responses.
        # Despite the error being automatically handled, it doesn't show up in the API docs.
        # So if you want, you can document the "possible" response errors here (like 422, 500, 404, ...)
    }
)
@limiter.limit("<limit>")   # The first middleware, use this to define the rate limit of the route
                            # If you don't want it to have a rate limit, simply remove this decorator
async def route_func_name(request: Request, # Required for the 'limiter'
                          # Your params here (can be from prefix format, or query string).
                          _ = Depends(VerifyAccessToken)    # Authentication middleware, checking if user is authenticated.
                                                            # It'll check if the user has a valid JWT in the header (HTTP Bearer),
                                                            # as given after login/register via Supabase.
                                                            # You can remove it when testing, or if you don't want that route to
                                                            # need authentication.
                          ):
    ...Function job here...

    return result # Return response, or you can also
    # return ObjectResponseModel(data=result)     -> Template object return
    # return CollectionResponseModel(data=result) -> Template collection/list return
    # return MessageResponseModel(data=result)    -> Template message return
```

### 2. Route Parameters

Now, if you take a look at the route parameters in `routers/maps.py`, they look scary, don't they?
But actually, as I said, it's simple and not as complicated as you think. Let's break it down.

The format of a route parameter is:
```python
<name>: Annotated[<Type>, Field(<Parameter Config>)]
# Or if optional
<name>: Annotated[<Type>, Field(<Parameter Config>)] = <default_value>
```

You get `Annotated` from the `typing` module, and `Field` from the `fastapi` module.
Typically, here's an example:

```python
from typing import Annotated, Optional
from fastapi import Field

# If there's validation, you should define it outside
ExampleType = Annotated[int, Field(ge=5)] # Must >= 5

@router.get("/route")
async def route(
    request: Request,
    param_name: Annotated[
        ExampleType,
        Field(
            default=<default value here>, # Default value here, omit to make it required.
            alias="<param alias here, when parsing>",
            title="<The title of the param, for API docs>",
            description="<The description of the param, for API docs>"
        )],
    example_optional_param: Annotated[
        ExampleType,
        Field(
            default=10,     # Default value is 10, making it optional
            alias="eop",    # Short for "example_optional_param",
            title="Example Optional Param",
            description="An example optional params"
        )],
    example_mix_param: Annotated[
        Optional[str], # And this one is not forced to be from Annotated or anything, but can be whatever that FastAPI can understand.
        Field(...)
    ]):
    ...
```

See! It's not as scary as you thought; they're just for validation and API documentation!

### 3. Schema Templates

Now, here's what you've been waiting for: what are these "templates" I'm yapping about???
Well, this FastAPI Backend template provides a standard response format, which is:
+ It should respond with a JSON object (not a raw value or array).
+ It should have two parameters for client response information:
    + `status` : Quick response status check, `ok` if success, `error` if failure.
    + `result` : The response type, commonly (and predefined) are:
        + `object` : Single object responses
        + `collections` : Multiple object responses
        + `error` : Error responses
        + `message` : Message responses

Okay, now how to use it? Take a look at `schemas/__init__.py` (basic template) and `schemas/errors.py`.

Usually, you'll want to use the predefined templates for this. Let's say you have a model you want to return/response:

```python
class ExampleModel(BaseModel):
    value: int
```

For returning a single object, use `ObjectResponseSchema`. For example:

```python
from schemas import ObjectResponseSchema

@router.get("/route")
def route():
    return ObjectResponseSchema(data=ExampleModel(value=2))

# Will response
{
    "status" : "ok",
    "result" : "object",
    "data" : {
        "value" : 2
    }
}
```

For returning multiple objects, use `CollectionsResponseSchema`. For example:

```python
from schemas import CollectionsResponseSchema

@router.get("/route")
def route():
    return CollectionsResponseSchema(data=[ExampleModel(value=2), ExampleModel(value=3)])

# Will response
{
    "status" : "ok",
    "result" : "collections",
    "data" : [
        {
            "value" : 2
        },
        {
            "value" : 3
        }
    ]
}
```

For message responses, use `MessageResponseSchema`. For example:

```python
from schemas import MessageResponseSchema

@router.get("/route")
def route():
    return MessageResponseSchema(data="Hello")

# Will response
{
    "status" : "ok",
    "result" : "message",
    "data" : "Hello"
}
```

For error responses, you can either use `BaseErrorResponseSchema`:

```python
from schemas import BaseErrorResponseSchema

@router.get("/route")
def route():
    return BaseErrorResponseSchema(data="Error Message")

# Will response
{
    "status" : "error",
    "result" : "error",
    "data" : "Error Message"
}
```

Or use `ErrorResponseSchema` (from `schemas/errors`) for a more HTTP-like response:

```python
from schemas.error import ErrorResponseSchema, ErrorDetailSchema
from fastapi.responses import JSONResponse

@router.get("/route")
def route():
    return ErrorResponseSchema(
        data=[
            ErrorDetailSchema(code=404, detail="Error 1 code 404 example"),
            ErrorDetailSchema(code=500, detail="Error 2 code 500 example")
        ]
    )
    # Note that the status code here when return is still 200, so usually you want to wrap it inside JSONResponse like
    return JSONResponse(
        status_code=404, # A overral status code here
        content=ErrorResponseSchema(
            data=[
                ErrorDetailSchema(code=404, detail="Error 1 code 404 example"),
                ErrorDetailSchema(code=500, detail="Error 2 code 500 example")
            ]
        ).model_dump(mode='json')
    )

# Will response
{
    "status" : "error",
    "result" : "error",
    "data" : [
        {
            "code" : 404,
            "detail" : "Error 1 code 404 example"
        },
        {
            "code" : 500
            "detail" : "Error 2 code 500 example"
        }
    ]
}
```

Yes, but usually, if you want to respond with an error and don't need manual control, then as mentioned before, you can raise an `HTTPException`. It's a cleaner way to do it.

If you want to create a response schema, override `BaseResponseSchema` (inside `schemas/__init__.py`). For example:

```python
from schemas import BaseResponseSchema, ResponseStatusType, ResponseResultType
from pydantic import BaseModel

class CustomIntResponseSchema(BaseResponseSchema, BaseModel):
    status = ResponseStatusType.OK      # The status of the response
    result = ResponseResultType.Object  # The result type of the response
    value: int

# To return in route, just call
return CustomIntResponseSchema(value=2) # Or your given value
```

This will response:
```json
{
    "status" : "ok",
    "result" : "object",
    "value" : 2
}
```

Now that's a quick look at the Backend template. For the `Handlers` and `QuerySystem` implementation guide, check out `Guideline.md` (or the short version, `Guideline-Short.md`).
