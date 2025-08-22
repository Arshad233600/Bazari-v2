import * as admin from "firebase-admin";
export type DailyKpi = { ctr?: number; diversity?: number; impressions?: number; clicks?: number; };
export async function readDailyKpi(date: Date){
  const db = admin.firestore();
  const id = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
  const snap = await db.collection("stats").doc("kpis").collection("daily").doc(id).get();
  return snap.exists ? snap.data() as DailyKpi : null;
}