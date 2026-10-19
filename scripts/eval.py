"""Local behavioral trial runner. No API key in repo; no automatic permission bypass."""
from pathlib import Path
import argparse,subprocess,json,datetime,shutil,tempfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--scenario',default='challenge-one-question')
p.add_argument('--execute',action='store_true')
p.add_argument('--timeout',type=int,default=120)
a=p.parse_args()
cases=json.loads((ROOT/'evals/behavioral.json').read_text())
case=next((x for x in cases if x['id']==a.scenario),None)
if case is None:p.error('Unknown scenario')
if not a.execute:
 print(json.dumps({'status':'NOT_RUN','scenario':a.scenario,'requires':'authenticated local claude CLI; use --execute'}))
 raise SystemExit(0)
if not shutil.which('claude'):raise SystemExit('Claude CLI missing; no test executed')
with tempfile.TemporaryDirectory(prefix='warrior-eval-') as d:
 work=Path(d)
 fixture=ROOT/case['fixture']
 if not fixture.is_dir():raise SystemExit('Fixture missing')
 for file in fixture.rglob('*'):
  if file.is_file():
   dest=work/file.relative_to(fixture);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dest)
 # Install actual tested skill into the isolated fixture, not the repository.
 skill='the-scroll' if 'scroll' in a.scenario else 'the-challenge'
 install=subprocess.run(['python3',str(ROOT/'scripts/install.py'),str(work),skill,'--host','claude'],capture_output=True,text=True)
 if install.returncode:raise SystemExit('Fixture installation failed: '+install.stderr)
 try:
  result=subprocess.run(['claude','-p',case['prompt']],cwd=work,capture_output=True,text=True,timeout=a.timeout)
  transcript=result.stdout;stderr=result.stderr;code=result.returncode
  question_count=transcript.count('?')
  heuristic=(code==0 and question_count==1) if case['check']=='one_question' else None
  report={'scenario':a.scenario,'exit_code':code,'question_marks':question_count,
          'heuristic_pass':heuristic,'manual_review':'REQUIRED','skill_installed':skill,
          'files_written':[str(x.relative_to(work)) for x in work.rglob('*') if x.is_file()]}
 except subprocess.TimeoutExpired as e:
  transcript=(e.stdout or b'').decode(errors='replace') if isinstance(e.stdout,bytes) else (e.stdout or '')
  stderr='Timed out';report={'scenario':a.scenario,'status':'TIMEOUT','manual_review':'REQUIRED'}
 stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
 out=ROOT/'evals/runs'/(stamp+'-'+a.scenario);out.mkdir(parents=True,exist_ok=True)
 (out/'transcript.txt').write_text(transcript)
 (out/'stderr.txt').write_text(stderr)
 (out/'result.json').write_text(json.dumps(report,indent=2))
 print(json.dumps({'artifact':str(out),'result':report},indent=2))
