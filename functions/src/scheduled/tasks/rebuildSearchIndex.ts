import * as admin from "firebase-admin";
import algoliasearch from "algoliasearch";
type Product = { title:string; price:number; currency:string; createdAt?: any; active?: boolean; images?: string[]; sellerId?:string; };
const appId = process.env.ALGOLIA_APP_ID as string;
const apiKey = process.env.ALGOLIA_API_KEY as string;
const indexName = process.env.ALGOLIA_INDEX_NAME || "products";
export async function rebuildSearchIndex(){
  if(!appId || !apiKey){ console.log("Algolia keys missing, skipping."); return; }
  const client = algoliasearch(appId, apiKey); const index = client.initIndex(indexName);
  const db=admin.firestore(); const snap=await db.collection("products").where("active","==",true).get();
  const objs = snap.docs.map(d=>{ const x=d.data() as Product; return {
    objectID: d.id, title:x.title, price:x.price, currency:x.currency,
    createdAt: x.createdAt? (x.createdAt.toMillis? x.createdAt.toMillis(): x.createdAt): null,
    images: x.images??[], sellerId:x.sellerId??null
  };});
  if (objs.length) await index.saveObjects(objs, { autoGenerateObjectIDIfNotExist:false });
  console.log(`Algolia pushed: ${objs.length}`);
}