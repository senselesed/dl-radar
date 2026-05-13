const { initializeApp } = require("firebase/app");
const { getDatabase, ref, set } = require("firebase/database");

const firebaseConfig = {
    databaseURL: "https://urlink.firebaseio.com"
};

const app = initializeApp(firebaseConfig);
const db = getDatabase(app);

set(ref(db, 'radar'), {
    sent_at: Math.floor(Date.now() / 1000),
    local: { id: 3, x: 0, y: 0 },
    allies: [0],
    enemies: [0]
}).then(() => {
    console.log("Структура 'radar' успешно создана!");
    process.exit();
});
