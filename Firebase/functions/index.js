



// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();


//exports.addMessage = functions.https.onRequest(async (req, res) => {
//// [END addMessageTrigger]
//  // Grab the text parameter.
//  const original = req.query.text;
//  // [START adminSdkPush]
//  // Push the new message into the Realtime Database using the Firebase Admin SDK.
//  const snapshot = await admin.database().ref('/messages').push({original: original});
//  // Redirect with 303 SEE OTHER to the URL of the pushed object in the Firebase console.
//  res.redirect(303, snapshot.ref.toString());
//  // [END adminSdkPush]
//});

exports.createInitialList = functions.auth.user().onCreate((user) => {
    
    const name = "My New List";
    
    return admin.database().ref('filmLists').push({
        "name": name,
        "owner": user.uid
    });
});



exports.addUserToListTheyCreate = functions.database.ref('/filmLists/{listId}')
    .onCreate((snapshot, context) => {
    
        const uid = snapshot.child('owner').val();
        const listId = context.params.listId;
        const name = snapshot.child('name').val();
    
        console.log('uid = ' + uid);
        console.log('listId = ' + listId);
        console.log('name = ' + name);
    
        return admin.database().ref('members/'+uid+'/'+listId).set({
            "name": name,
            "owner": true
        });
    });


exports.removeUserFromListTheyDelete = functions.database.ref('/filmLists/{listId}')
    .onDelete((snapshot, context) => {
    
        const uid = snapshot.child('owner').val();
        const listId = context.params.listId;
        const name = snapshot.child('name').val();
    
        console.log('uid = ' + uid);
        console.log('listId = ' + listId);
        console.log('name = ' + name);
    
        return admin.database().ref('members/'+uid+'/'+listId).remove();
    });

exports.onRenameList = functions.database.ref('/filmLists/{listId}')
    .onUpdate((change, context) => {
    
        const before = change.before;  // DataSnapshot before the change
        const after = change.after;  // DataSnapshot after the change
    
        const uid = after.child('owner').val();
        const listId = context.params.listId;
        const name = after.child('name').val();
    
        console.log('uid = ' + uid);
        console.log('listId = ' + listId);
        console.log('name = ' + name);
    
        return admin.database().ref('members/'+uid+'/'+listId+"/name").set(name);
    });


