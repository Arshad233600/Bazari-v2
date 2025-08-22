import * as admin from "firebase-admin";
import { MeiliSearch } from "meilisearch";
type Product = { title:string; price:number; currency:string; createdAt?: any; active?: boolean; images?: string[]; sellerId?:string; };
const host = process.env.MEILI_HOST as string;
const key = process.env.MEILI_API_KEY as string;
const indexName = process.env.MEILI_INDEX_NAME || "products";
export async function rebuildSearchIndexMeili(){
  if(!host || !key){ console.log("Meili keys missing, skipping."); return; }
  const client = new MeiliSearch({ host, apiKey: key }); const index = client.index(indexName);
  try { await client.deleteIndex(indexName); } catch(_) {}
  await client.createIndex(indexName, { primaryKey: "id" });
  const db=admin.firestore(); const snap=await db.collection("products").where("active","==",true).get();
  const docs = snap.docs.map(d=>{ const x=d.data() as Product; return {
    id: d.id, title:x.title, price:x.price, currency:x.currency,
    createdAt: x.createdAt? (x.createdAt.toMillis? x.createdAt.toMillis(): x.createdAt): null,
    images: x.images??[], sellerId:x.sellerId??null
  };});
  if (docs.length){ const t = await index.addDocuments(docs); await client.waitForTask(t.taskUid); }
  await index.updateSettings({ searchableAttributes:["title"], filterableAttributes:["sellerId","currency"], sortableAttributes:["price","createdAt"] });
  console.log(`Meili pushed: ${docs.length}`);
}