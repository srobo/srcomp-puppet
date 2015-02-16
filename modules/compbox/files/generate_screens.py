import lxml.html
import tempfile
import os.path
import shutil
import subprocess

TARGET = '/var/www/html'
SOURCE = '/var/www/screens'
VULCANIZE = '/usr/local/bin/vulcanize'

FILES = ('arena.html',
         'outside.html',
         'shepherding.html')

for fn in FILES:
    dst = os.path.join(TARGET, fn)
    src = os.path.join(SOURCE, fn)
    tree = lxml.html.parse(src)
    for comp in tree.getiterator('sr-comp'):
        comp.attrib['streamurl'] = '/stream'
        comp.attrib['apiurl'] = '/comp-api'
    tree.write(dst, encoding='utf-8', method='html')
    subprocess.check_call(('vulcanize', fn,
                              '--inline',
                              '--strip',
                              '-o', fn),
                          cwd=TARGET)

shutil.rmtree(os.path.join(TARGET, 'components'),
              ignore_errors=True)
shutil.copytree(os.path.join(SOURCE, 'components'),
                os.path.join(TARGET, 'components'))
shutil.rmtree(os.path.join(TARGET, 'bower_components'),
              ignore_errors=True)
shutil.copytree(os.path.join(SOURCE, 'bower_components'),
                os.path.join(TARGET, 'bower_components'))
