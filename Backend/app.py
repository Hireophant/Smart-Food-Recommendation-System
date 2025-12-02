import dotenv, schemas.errors
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, Request, status
from contextlib import asynccontextmanager
from starlette.exceptions import HTTPException as StarletteHTTPException
from slowapi.errors import RateLimitExceeded
from utils import Config, Logger
from middleware.rate_limit import limiter

#* Call when initialize the backend
async def onInitialize() -> bool:
    #* Pre-initialization
    dotenv.load_dotenv()
    
    if not Config.Initialize():
        return False
    Logger.Initialize()
    
    #* Initialize here
            
    return True

#* Call when deinitialize the backend
async def onDeinitialize():
    #* Deinitialize here
    
    return

#* The lifespan of the FastAPI app.
@asynccontextmanager
async def appLifespan(app: FastAPI):
    # Initialize
    if not await onInitialize():
        Logger.LogError("Failed to initialize! Exiting...")
        return
    
    yield
    
    # Deinitialize
    await onDeinitialize()

app = FastAPI(lifespan=appLifespan)

# Add rate limiter state
app.state.limiter = limiter

#* Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Let as intended.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

#* Error handler

@app.exception_handler(RateLimitExceeded)
async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content=schemas.errors.ErrorResponseSchema(
            data=[
                schemas.errors.ErrorDetailSchema(
                    code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Rate limit exceeded: {exc.detail}"
                )
            ]
        ).model_dump(mode='json')
    )

@app.exception_handler(StarletteHTTPException)
async def starlette_http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content= schemas.errors.ErrorResponseSchema(
            data=[
                schemas.errors.ErrorDetailSchema(
                    code=exc.status_code,
                    detail=str(exc.detail)
                )
            ]
        ).model_dump(mode='json')
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content=schemas.errors.ErrorResponseSchema(
            data=[
                schemas.errors.ErrorDetailSchema(
                    code=exc.status_code,
                    detail=str(exc.detail)
                )
            ]
        ).model_dump(mode='json')
    )

@app.exception_handler(RequestValidationError)
async def request_validation_error_handler(request: Request, exc: RequestValidationError):
    def format_message(e) -> schemas.errors.ErrorDetailSchema:
        # e is a dict with keys: 'loc', 'msg', 'type', etc.
        loc = ".".join(str(x) for x in e.get("loc", []))
        msg = e.get("msg", "Invalid input.")
        err_type = e.get("type", "unknown_error")
        detail = f"{loc} ({err_type}): {msg}" if loc else f"({err_type}): {msg}"
            
        return schemas.errors.ErrorDetailSchema(
            code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail
        )

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=schemas.errors.ErrorResponseSchema(
            data=[format_message(e) for e in exc.errors()]
        ).model_dump(mode='json')
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=schemas.errors.ErrorResponseSchema(
            data=[
                schemas.errors.ErrorDetailSchema(code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                                 detail=f"{type(exc).__name__}: {str(exc)}")
            ]
        ).model_dump(mode='json')
    )