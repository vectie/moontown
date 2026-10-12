#!/usr/bin/env python3
"""Exercise the actual claim_compare executable. Retain every fixture and output."""
import csv, hashlib, json, os, pathlib, shutil, subprocess, sys
exe = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
out.mkdir(parents=True, exist_ok=True)
sample = pathlib.Path(__file__).resolve().parents[1] / "assets/samples/claim-comparison"
root = out / "sources"
root.mkdir(exist_ok=True)
for p in (sample / "sources").iterdir():
    shutil.copyfile(p, root / p.name)
rows = list(csv.reader((sample / "claims.csv").open()))
results = []
def table(name, data, delimiter=",", bom=False):
    p = out / name
    with p.open("w", newline="", encoding="utf-8-sig" if bom else "utf-8") as f:
        csv.writer(f, delimiter=delimiter, lineterminator="\r\n").writerows(data)
    return p

def invoke(name, args, success=True):
    result = subprocess.run([str(exe), *map(str,args)], capture_output=True, timeout=10)
    (out / (name+".stdout")).write_bytes(result.stdout)
    (out / (name+".stderr")).write_bytes(result.stderr)
    assert (result.returncode == 0) == success, (name, result.returncode, result.stderr)
    if not success:
        assert result.returncode == 1 and result.stdout == b"" and result.stderr, name
    results.append({"case":name,"exit":result.returncode,"passed":True})
    return result.stdout

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
protected = {str(p):sha(p) for p in sample.rglob("*") if p.is_file()}
first = json.loads(invoke("sample-json", [sample/"claims.csv", sample/"sources", "json"]))
assert first["contract"] == "moontown.claim-comparison.v1" and first["state"] == "pending_review"
assert [g["state"] for g in first["groups"]] == ["different_values", "single_book", "same_value"]
assert first["groups"][0]["claims"][1]["value"] == "December"
assert first["table_digest"] == "sha256:"+sha(sample/"claims.csv")
for source in first["sources"]:
    p = sample/"sources"/source["path"]
    assert source["digest"] == "sha256:"+sha(p) and source["size_bytes"] == len(p.read_bytes())
markdown = invoke("sample-markdown", [sample/"claims.csv",sample/"sources","markdown"])
assert b"November" in markdown and b"December" in markdown and b"pending_review" in markdown
for filename, delimiter, bom in [("bom.tsv","\t",True),("round.csv",",",False)]:
    result = json.loads(invoke(filename, [table(filename,rows,delimiter,bom),root,"json"]))
    assert result["groups"] == first["groups"] and result["sources"] == first["sources"]
assert invoke("sample-expected-json",[sample/"claims.csv",sample/"sources","json"]) == (sample/"comparison.json").read_bytes()
assert markdown == (sample/"comparison.md").read_bytes()
assert b"Usage:" in invoke("help",["--help"])
invoke("bad-format",[sample/"claims.csv",root,"html"],False)
invoke("bad-args",[],False)
for name, data in [("empty",rows[:1]),("header",[["bad"], ["bad"]]),("duplicate",rows+[rows[1]]),("blank-context",[rows[0],[*rows[1][:3]," ",*rows[1][4:]]]),("missing-source",[rows[0],[*rows[1][:5],"missing.txt",rows[1][6]]]),("quote-mismatch",[rows[0],[*rows[1][:6],"not present"]]),("traversal",[rows[0],[*rows[1][:5],"../outside.txt",rows[1][6]]]),("absolute",[rows[0],[*rows[1][:5],str(root/"sales.txt"),rows[1][6]]])]:
    invoke(name,[table(name+".csv",data),root,"json"],False)
invalid=out/"invalid.csv"; invalid.write_bytes(b"\xff")
invoke("invalid-table-utf8",[invalid,root,"json"],False)
malformed=out/"malformed.csv"; malformed.write_text(','.join(rows[0])+'\n"unclosed')
invoke("malformed-csv",[malformed,root,"json"],False)
(root/"invalid.txt").write_bytes(b"\xff")
(root/"oversize.txt").write_bytes(b"x"*262145)
(root/"directory").mkdir(exist_ok=True)
os.mkfifo(root/"pipe")
(out/"outside.txt").write_text("Launch: November")
(root/"escape.txt").symlink_to(out/"outside.txt")
for name in ["invalid.txt","oversize.txt","directory","pipe","escape.txt"]:
    data=[rows[0],[*rows[1][:5],name,rows[1][6]]]
    invoke(name,[table(name+".csv",data),root,"json"],False)
(root/"inside.txt").symlink_to(root/"sales.txt")
inside=json.loads(invoke("internal-symlink",[table("inside.csv",[rows[0],[*rows[1][:5],"inside.txt",rows[1][6]]]),root,"json"]))
assert inside["sources"][0]["path"] == "inside.txt"
(root/"sales.txt").write_text((root/"sales.txt").read_text()+"New captured note\n")
changed=json.loads(invoke("changed-source",[sample/"claims.csv",root,"json"]))
assert changed["sources"][0]["digest"] != first["sources"][0]["digest"]
assert changed["groups"] == first["groups"]
value='[click](https://example.test) <script> & #title\n水'
(root/"markup.txt").write_text(value)
markup=invoke("literal-markup",[table("markup.csv",[rows[0],["m","A","t","c",value,"markup.txt",value]]),root,"markdown"])
assert b"<script>" not in markup and b"[click](" not in markup
assert {str(p):sha(p) for p in sample.rglob("*") if p.is_file()} == protected
(out/"RESULTS.json").write_text(json.dumps({"passed":len(results),"cases":results,"sample_inputs_unchanged":True},indent=2)+"\n")
print(f"{len(results)} executable cases passed; sample inputs unchanged")
