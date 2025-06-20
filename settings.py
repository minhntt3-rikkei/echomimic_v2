from pydantic import Field
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv(override=True)

class Settings(BaseSettings):
    model_path: str = Field(default="./models")
    model_det_name: str = Field(default="yolox_l.onnx")
    model_pose_name: str = Field(default="dw-ll_ucoco_384.onnx")

settings = Settings()
