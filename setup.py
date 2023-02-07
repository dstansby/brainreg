import glob
import os
import pathlib
from os import path

from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext as build_ext_orig


class CMakeExtension(Extension):
    def __init__(self, name):
        # don't invoke the original build_ext for this special extension
        super().__init__(name, sources=[])


class build_ext(build_ext_orig):
    def run(self):
        for ext in self.extensions:
            self.build_cmake(ext)
        super().run()

    def build_cmake(self, ext):
        cwd = pathlib.Path().absolute()

        # these dirs will be created in build_py, so if you don't have
        # any python sources to bundle, the dirs will be missing
        build_temp = pathlib.Path(self.build_temp).resolve()
        build_temp.mkdir(parents=True, exist_ok=True)
        extdir = (
            pathlib.Path(self.get_ext_fullpath(ext.name)).parent / ext.name
        )
        extdir.mkdir(parents=True, exist_ok=True)

        # example of cmake args
        config = "Debug" if self.debug else "Release"
        cmake_args = [
            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY="
            + str(extdir.parent.absolute()),
            "-DCMAKE_BUILD_TYPE=" + config,
            "-DUSE_SSE=OFF",
        ]

        # example of build args
        build_args = [
            "--config",
            config,
        ]

        os.chdir(build_temp)
        self.spawn(["cmake", str(cwd / ext.name)] + cmake_args)
        if not self.dry_run:
            self.spawn(["cmake", "--build", "."] + build_args)

        os.chdir(cwd)

        # Copy binaries from temp build folder to wheel
        binaries = glob.glob(str(build_temp / "reg-apps" / "*"))
        binaries = [
            b
            for b in binaries
            if os.access(b, os.X_OK)
            and pathlib.Path(b).name.startswith("reg_")
        ]


this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, "README.md"), encoding="utf-8") as f:
    long_description = f.read()

requirements = [
    "bg-atlasapi",
    "bg-space",
    "numpy",
    "configparser",
    "scikit-image",
    "multiprocessing-logging",
    "configobj",
    "slurmio",
    "imio",
    "fancylog",
    "imlib>=0.0.26",
]


setup(
    name="brainreg",
    version="0.4.0",
    description="Automated 3D brain registration",
    long_description=long_description,
    long_description_content_type="text/markdown",
    install_requires=requirements,
    extras_require={
        "napari": [
            "napari[pyside2]",
            "brainreg-napari",
            "brainglobe-napari-io",
            "brainreg-segment>=0.0.2",
        ],
        "dev": [
            "black",
            "pytest-cov",
            "pytest",
            "coverage",
            "bump2version",
            "pre-commit",
            "flake8",
        ],
    },
    python_requires=">=3.8",
    package_dir={"": "src"},
    ext_modules=[CMakeExtension("niftyreg")],
    cmdclass={
        "build_ext": build_ext,
    },
    entry_points={"console_scripts": ["brainreg = brainreg.cli:main"]},
    include_package_data=True,
    author="Adam Tyson, Charly Rousseau",
    author_email="code@adamltyson.com",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Operating System :: OS Independent",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Intended Audience :: Developers",
        "Intended Audience :: Science/Research",
    ],
    zip_safe=False,
)
