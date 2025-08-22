import * as admin from "firebase-admin";
export async function computeTrendingReal(){
  const db=admin.firestore();
  await db.collection("public").doc("trending").set({
    items: [], updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge:true });
}