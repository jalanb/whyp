"""setup"""

from distutils.core import  setup

import whyp

description=whyp.__doc__

setup(
    name=whyp.__name__,
    version=whyp.__version__,
    description=description.splitlines()[0],
    long_description=description,
    url='https://github.com/jalanb/%s' % whyp.__name__,
    packages=['whyp'],
    download_url='https://github.com/jalanb/%s/tarball/v%s' % (
        whyp.__name__, whyp.__version__),
    license='MIT License',
    author='jalanb',
    author_email='github@al-got-rhythm.net',
    platforms='any',
    classifiers=[
        'Programming Language :: Python :: 3.7',
        'Development Status :: 2 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Topic :: Software Development',
        'Topic :: Utilities'
    ],
    install_requires=[
        'pprintpp',
        'pysyte',
        'pyyaml',
        'requests',
    ],
    scripts=['bin/whyp'],
)

