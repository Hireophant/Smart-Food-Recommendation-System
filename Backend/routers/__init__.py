from fastapi import APIRouter, Depends
from middleware.limiter import limiter
from middleware.auth import VerifyAccessToken
from query import QuerySystem  # import class QuerySystem
                                # (bạn thay bằng đúng file của bạn)

router = APIRouter(prefix="/query", tags=["Query System"])

# Khởi tạo QuerySystem (cho VietMap)
query = QuerySystem(api_key="44d90197266468aca3576ff23c1ccd194ec61aec1b7d1949")


# ✔️ Test rate limit
@router.get("/test")
@limiter.limit("5/minute")
def test():
    return {"message": "OK"}


# ✔️ Geocode VietMap (có JWT)
@router.get("/vietmap/geocode")
async def geocode(address: str, user=Depends(VerifyAccessToken)):
    return await query.geocode(address)


# ✔️ Reverse geocode VietMap (option)
@router.get("/vietmap/reverse")
async def reverse_geocode(lat: float, lng: float, user=Depends(VerifyAccessToken)):
    return await query.reverse_geocode(lat, lng)
