from setuptools import setup, find_packages

setup(
    name="mangekyou_mcp",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "fastapi>=0.103.1",
        "uvicorn[standard]>=0.23.2",
        "pydantic>=2.4.2",
        "requests>=2.31.0",
    ],
    python_requires=">=3.8",
)