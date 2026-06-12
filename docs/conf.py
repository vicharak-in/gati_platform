# -- Project information
project = 'Gati Platform'
copyright = '2025, Vicharak Computers PVT LTD'
author = 'Vicharak'

# -- General configuration
extensions = [
    'sphinxcontrib.bibtex',
    'myst_parser',
]

bibtex_bibfiles = ['refs.bib']
templates_path = ['_templates']
exclude_patterns = []

# -- HTML output
html_theme = 'alabaster'
html_static_path = ['_static']

# -- MyST Parser settings
myst_enable_extensions = [
    'colon_fence',
    'deflist',
]
