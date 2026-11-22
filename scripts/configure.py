#!/usr/bin/env python3
from pathlib import Path
import argparse,json
p=argparse.ArgumentParser();p.add_argument('--config',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[1];source=a.config or root/'config/voice.local.json'
if not source.exists():source=root/'config/voice.example.json'
config=json.loads(source.read_text())
assert not (set(config)-{'backendUrl','enterpriseBackendUrl','accountId','appId','businessNumber','supportName','pushEnvironment','firebase'}),'Unknown/private config field; only public application settings are allowed'
assert not (set(config.get('firebase',{}))-{'appId','apiKey','projectId','senderId'}),'Only Firebase client options belong in app'
for name in ['lib/voice_config.json','android/app/src/main/assets/voice_config.json','ios/Runner/voice_config.json']:
 path=root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(config,ensure_ascii=False,indent=2)+'\n')
print('Generated Dart/Android/iOS config without account credentials')
