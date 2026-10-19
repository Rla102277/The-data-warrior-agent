"""Optional local headless behavioral evaluation. Never run untrusted fixtures without sandboxing."""
from pathlib import Path
import argparse,subprocess,json,datetime,os,shutil,re
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--host',choices=['claude'],default='claude')
p.add_argument('--scenario',default='challenge-one-question')
p.add_argument('--execute',action='store_true',help='Actually invoke local Claude CLI')
p.add_argument('--timeout',type=int,default=120)
a=p.parse_args()
cases=json.loads((ROOT/'evals/behavioral.json').read_text())
case=next((x for x in cases if x['id']==a.scenario),None)
if case is None:p.error('Unknown scenario')
if not a.execute:
    print(json.dumps({'status':'NOT_RUN','scenario':a.scenario,'command':'python3 scripts/eval.py --execute --scenario '+a.scenario},indent=2))
    raise SystemExit(0)
if shutil.which('claude') is None:raise SystemExit('Claude CLI not installed; no test executed')
stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
out=ROOT/'evals/runs'/stamp
out.mkdir(parents=True,exist_ok=True)
# Execute only inside the controlled fixture repository, without permission bypass.
fixture=ROOT/case['fixture']
if not fixture.is_dir():raise SystemExit('Missing fixture directory')
cmd=['claude','-p',case['prompt']]
try:
    result=subprocess.run(cmd,cwd=fixture,capture_output=True,text=True,timeout=a.timeout)
    transcript=result.stdout
    (out/'transcript.txt').write_text(transcript)
    (out/'stderr.txt').write_text(result.stderr)
    # Conservative heuristic, not a semantic judge. Manual review remains required.
    count=transcript.count('?')
    passed=result.returncode==0 and count==1 if case['check']=='one_question' else None
    report={'scenario':a.scenario,'exit_code':result.returncode,'question_marks':count,
            'heuristic_pass':passed,'manual_review':'REQUIRED','command':cmd}
except subprocess.TimeoutExpired:
    report={'scenario':a.scenario,'status':'TIMEOUT','manual_review':'REQUIRED'}
(out/'result.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'artifact':str(out),'result':report},indent=2))
