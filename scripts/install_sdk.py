#!/usr/bin/env python3
"""Install only the checksummed delivery into generated vendor/, never from live source."""
from pathlib import Path
import hashlib,json,shutil,tarfile,tempfile
root=Path(__file__).resolve().parents[1];name='caresoft_customer_voice-0.5.0';archive=root/'packages'/(name+'.tar.gz')
line=(root/'packages/SHA256SUMS').read_text().splitlines();assert len(line)==1,'Expected one current archive'
digest,filename=line[0].split();assert filename in {archive.name,'packages/'+archive.name}
assert hashlib.sha256(archive.read_bytes()).hexdigest()==digest,'SDK archive checksum mismatch'
vendor=root/'vendor';vendor.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(dir=vendor) as tmp:
 stage=Path(tmp)
 with tarfile.open(archive) as t:
  for m in t.getmembers():
   p=Path(m.name)
   assert m.isfile() and not p.is_absolute() and p.parts[0]==name and '..' not in p.parts,'Unsafe archive entry'
   f=stage/p;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(t.extractfile(m).read())
 package=stage/name;manifest=json.loads((package/'native-manifest.json').read_text())
 for file,expected in manifest['sha256'].items():
  path=Path(file);assert not path.is_absolute() and '..' not in path.parts
  assert hashlib.sha256((package/path).read_bytes()).hexdigest()==expected,'Native checksum mismatch: '+file
 target=vendor/name
 if target.exists():shutil.rmtree(target)
 shutil.move(str(package),str(target))
print('Installed',name,'with',len(manifest['sha256']),'verified native files')
