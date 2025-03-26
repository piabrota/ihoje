from setuptools import setup, find_packages

setup(
    name="mangekyou_mcp",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "fastapi>=0.111.0",
        "uvicorn[standard]>=0.27.1",
        "pydantic>=2.4.2",
        "requests>=2.31.0",
        "python-dotenv>=1.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "httpx>=0.24.0",
            "ruff>=0.0.278",
            "black>=23.3.0",
            "isort>=5.12.0",
        ],
    },
    python_requires=">=3.8",
)