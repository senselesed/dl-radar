const { app, BrowserWindow, globalShortcut, screen } = require('electron');

let mainWindow;
let isClickThrough = true;

function createWindow() {
    const { width, height } = screen.getPrimaryDisplay().workAreaSize;

    mainWindow = new BrowserWindow({
        width: width,
        height: height,
        x: 0,
        y: 0,
        transparent: true,
        frame: false,
        alwaysOnTop: true,
        skipTaskbar: true,
        resizable: false,
        fullscreenable: true,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    mainWindow.setIgnoreMouseEvents(isClickThrough, { forward: true });

    mainWindow.loadFile('index.html');
    mainWindow.maximize();

    globalShortcut.register('\\', () => {
        isClickThrough = !isClickThrough;
        mainWindow.setIgnoreMouseEvents(isClickThrough, { forward: true });
        
        mainWindow.webContents.executeJavaScript(`
            if (${!isClickThrough}) {
                document.body.classList.add('edit-mode');
            } else {
                document.body.classList.remove('edit-mode');
            }
        `).catch(console.error);

        console.log(`Edit mode: ${!isClickThrough}`);
    });
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', function () {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') app.quit();
});

app.on('will-quit', () => {
    globalShortcut.unregisterAll();
});