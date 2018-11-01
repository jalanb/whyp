"""setup"""

from distutils.core import  setup

import whyp

setup(
    name="whyp",
    version=whyp.version,
    description=whyp.__doc__.splitlines()[0],
    url="https://github.com/jalanb/whyp",
    requires=["argparse"],
    packages=["whyp"],
    scripts=["bin/whyp"],
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

