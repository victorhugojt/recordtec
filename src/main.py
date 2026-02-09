from fastapi import FastAPI
from controllers.health import router as health_router
from controllers.generes import router as generes_router
import uvicorn

app = FastAPI()

app.include_router(health_router)
app.include_router(generes_router)

def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
