"""setup"""

from distutils.core import  setup

import what

setup(
    name="what",
    version=what.version,
    description=what.__doc__.splitlines()[0],
    url="https://github.com/jalanb/what",
    requires=["argparse"],
    packages=["what"],
    scripts=["bin/what"],
    platforms='any',
    classifiers=[
        'Development Status :: 2 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Topic :: Software Development',
        'Topic :: Utilities'
    ],
    author="jalanb",
    author_email='github@al-got-rhythm.net',
)

