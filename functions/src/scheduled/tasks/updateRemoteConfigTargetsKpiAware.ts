import { getRemoteConfig } from "firebase-admin/remote-config";
import { readDailyKpi } from "../shared/kpi";
export async function updateRemoteConfigTargetsKpiAware(){
  const rc = getRemoteConfig();
  const y = new Date(); y.setDate(y.getDate()-1);
  const kpi = await readDailyKpi(y);
  let lo=0.12, hi=0.16, dlo=0.55, dhi=0.70;
  if(kpi?.ctr && kpi.ctr>0 && kpi.ctr<0.8){
    const c=kpi.ctr; lo=Math.max(0.08, Math.min(c-0.01, 0.22)); hi=Math.max(lo+0.02, Math.min(c+0.01, 0.28));
  }
  if(typeof kpi?.diversity === "number"){
    const d=kpi.diversity; dlo=Math.max(0.45, Math.min(d-0.05, 0.80)); dhi=Math.max(dlo+0.05, Math.min(d+0.05, 0.90));
  }
  const t = await rc.getTemplate();
  t.parameters["targetCtrLow"]={ defaultValue:{ value:String(lo) } };
  t.parameters["targetCtrHigh"]={ defaultValue:{ value:String(hi) } };
  t.parameters["targetDivLow"]={ defaultValue:{ value:String(dlo) } };
  t.parameters["targetDivHigh"]={ defaultValue:{ value:String(dhi) } };
  await rc.publishTemplate(t);
}