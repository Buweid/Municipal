const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createFieldOfficer = functions.https.onCall(async (data, context) => {
  // 1. Only admins can call this
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Not logged in");
  }

  const callerDoc = await admin.firestore()
      .collection("users")
      .doc(context.auth.uid)
      .get();

  if (callerDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Admins only");
  }

  const { name, email, password, phone, nationalId } = data;

  // 2. Create Auth user (admin stays logged in — no side effects)
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: name,
  });

  // 3. Save to Firestore with role: fo
  await admin.firestore().collection("users").doc(userRecord.uid).set({
    uid: userRecord.uid,
    name,
    email,
    phone,
    nationalId,
    role: "fo",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, uid: userRecord.uid };
});