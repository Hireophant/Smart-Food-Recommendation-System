from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional


class SearchLocationModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Name: str = Field(default="", serialization_alias="name", description="Tên địa điểm")
    Address: Optional[str] = Field(default=None, serialization_alias="address", description="Địa chỉ")
    Type: Optional[str] = Field(default=None, serialization_alias="type", description="Loại địa điểm")
    Description: Optional[str] = Field(default=None, serialization_alias="description", description="Mô tả ngắn")
    Rating: Optional[float] = Field(default=None, serialization_alias="rating", description="Điểm đánh giá")
    Reviews: Optional[int] = Field(default=None, serialization_alias="reviews", description="Số lượng đánh giá")
    Price: Optional[str] = Field(default=None, serialization_alias="price", description="Khoảng giá")
    Latitude: Optional[float] = Field(default=None, serialization_alias="lat", description="Vĩ độ")
    Longitude: Optional[float] = Field(default=None, serialization_alias="lon", description="Kinh độ")
    PlaceId: Optional[str] = Field(default=None, serialization_alias="place_id", description="Google place id")
    PlaceIdSearch: Optional[str] = Field(
        default=None,
        serialization_alias="place_id_search",
        description="SERP place_id_search link",
    )
    Url: Optional[str] = Field(default=None, serialization_alias="url", description="Link liên quan")


class SearchOrganicResultModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Title: str = Field(default="", serialization_alias="title", description="Tiêu đề kết quả")
    Snippet: Optional[str] = Field(default=None, serialization_alias="snippet", description="Đoạn mô tả")
    Link: Optional[str] = Field(default=None, serialization_alias="link", description="Đường dẫn")
    Source: Optional[str] = Field(default=None, serialization_alias="source", description="Nguồn")


class SearchResponseModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    Query: str = Field(default="", serialization_alias="query", description="Từ khoá tìm kiếm")
    Location: str = Field(default="Vietnam", serialization_alias="location", description="Khu vực tìm kiếm")
    Locations: List[SearchLocationModel] = Field(
        default_factory=list,
        serialization_alias="locations",
        description="Danh sách địa điểm (nếu có)",
    )
    OrganicResults: List[SearchOrganicResultModel] = Field(
        default_factory=list,
        serialization_alias="organic_results",
        description="Danh sách kết quả tìm kiếm",
    )


class SearchResultFormattedModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    # Required by spec: a single variable named `result`.
    result: str = Field(default="", description="Chuỗi kết quả đã được format")
