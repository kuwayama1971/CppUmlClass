// main.js
const { createApp, ref, reactive, onMounted, onBeforeUnmount, nextTick, watch } = Vue;

createApp({
    setup() {
        // --- State ---
        const inDir = ref('');
        const outFile = ref('');
        const logs = ref([]);
        const autoScroll = ref(false);
        const outarea = ref(null);
        const hasExecuted = ref(false);
        const dirListRef = ref(null);
        const fileListRef = ref(null);
        
        // Container Refs for click-outside detection
        const mainInDirRef = ref(null);
        const mainOutFileRef = ref(null);

        // Suggestions
        const dirSuggestions = ref([]);
        const fileSuggestions = ref([]);

        // Dialogs
        const msgDialog = reactive({
            visible: false,
            message: '',
            title: 'Message',
            timeoutId: null
        });

        const dirDialog = reactive({
            visible: false,
            search: '',
            suggestions: [],
            selectedIndex: -1
        });

        const fileDialog = reactive({
            visible: false,
            search: '',
            suggestions: [],
            selectedIndex: -1
        });

        const settingDialog = reactive({
            visible: false,
            items: [], // { name, value, type, select, description, valueStr(for textarea) }
            version: ''
        });

        // WebSocket
        let ws = null;
        let connectRetryCount = 0;

        // --- Methods ---

        // Log
        const appendLog = (msg) => {
            logs.value.push(msg);
            if (autoScroll.value) {
                scrollToBottom();
            }
        };

        const scrollToBottom = () => {
            nextTick(() => {
                if (outarea.value) {
                    outarea.value.scrollTop = outarea.value.scrollHeight;
                }
            });
        };

        const onScroll = () => {
            if (outarea.value) {
                const h = outarea.value.scrollHeight - outarea.value.clientHeight;
                if (Math.abs(outarea.value.scrollTop - h) < 30) {
                    // autoScroll.value = true; 
                } else {
                    autoScroll.value = false;
                }
            }
        };

        // Dialogs
        const showMsgDialog = (msg, timeout = 0) => {
            msgDialog.message = msg;
            msgDialog.visible = true;
            if (msgDialog.timeoutId) clearTimeout(msgDialog.timeoutId);
            
            if (timeout > 0) {
                msgDialog.timeoutId = setTimeout(() => {
                    msgDialog.visible = false;
                }, timeout);
            }
        };

        const closeMsgDialog = () => {
            if (msgDialog.timeoutId) clearTimeout(msgDialog.timeoutId);
            msgDialog.visible = false;
        };

        // Server Connection
        const serverConnect = (url) => {
            ws = new WebSocket(url);
            ws.onopen = function () {
                ws.send("message to send");
                console.log("WebSocket connected");
            };
            ws.onmessage = function (evt) {
                if (evt.data.match(/^startup:/)) {
                    // file_name = evt.data.replace(/^startup:/, "");
                }
                else if (evt.data.match(/^app_start/)) {
                    showMsgDialog("処理中...");
                    hasExecuted.value = false;
                }
                else if (evt.data.match(/^app_end:normal/)) {
                    showMsgDialog("終了しました");
                    hasExecuted.value = true;
                }
                else if (evt.data.match(/^app_end:stop/)) {
                    showMsgDialog("中止しました");
                }
                else if (evt.data.match(/^app_end:error/)) {
                    showMsgDialog("<font color='red'>エラーが発生しました</font>");
                }
                else if (evt.data.match(/^popup:/)) {
                    const timeout_str = evt.data.match(/:(\d+):/);
                    const timeout = Number(timeout_str[1]);
                    showMsgDialog(evt.data.replace(/^popup:(\d+):/, ""), timeout);
                    hasExecuted.value = true;
                } else {
                    appendLog(evt.data);
                }
            };
            ws.onclose = function () {
                // alert("アプリケーションが終了しました!!");
                // window.close();
                console.log("WebSocket closed");
            };
            ws.onerror = function(err) {
                console.error("WebSocket error:", err);
            }
        };

        const sendMessage = (msg) => {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(msg);
            } else {
                console.warn("WebSocket is not connected");
            }
        };

        // Actions
        const exec = () => {
            logs.value = [];
            sendMessage("exec:" + inDir.value + "," + outFile.value);
        };

        const stop = () => {
            sendMessage("stop");
        };

        const openFile = () => {
            if (!hasExecuted.value) return;
            sendMessage("openfile:" + outFile.value);
        };

        // Autocomplete Logic
        const fetchSuggestions = async (term, kind, url) => {
            try {
                let resData = [];
                if (url.startsWith('history/')) {
                    const params = new URLSearchParams();
                    params.append('param1', term);
                    
                    const response = await fetch(url, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: params
                    });
                    if (response.ok) {
                        resData = await response.json();
                    }
                } else {
                    const finalUrl = `${url}&param1=${encodeURIComponent(term)}`;
                    const response = await fetch(finalUrl);
                    if (response.ok) {
                        resData = await response.json();
                    }
                }
                
                // Normalize to { label, value }
                if (Array.isArray(resData)) {
                    return resData.map(item => {
                        if (typeof item === 'string') {
                            return { label: item, value: item };
                        } else if (typeof item === 'object' && item !== null) {
                            return item; // Assume { label, value } structure
                        }
                        return { label: String(item), value: String(item) };
                    });
                }
                return [];
            } catch (e) {
                console.error(e);
                return [];
            }
        };

        // Input Handlers (Main Screen)
        const onInputDir = async () => {
            // autocomp_history("inDir", "history.json")
            if (inDir.value.length === 0) {
                 // dirSuggestions.value = [];
                 // return;
            }
            // For history, we send the term
            const res = await fetchSuggestions(inDir.value, '', 'history/history.json');
            dirSuggestions.value = res;
        };
        
        const selectDirSuggestion = (item) => {
            inDir.value = item.value;
            dirSuggestions.value = [];
        };

        const onInputFile = async () => {
            // autocomp_history("outFile", "out_history.json")
            const res = await fetchSuggestions(outFile.value, '', 'history/out_history.json');
            fileSuggestions.value = res;
        };

        const selectFileSuggestion = (item) => {
            outFile.value = item.value;
            fileSuggestions.value = [];
        };

        const onMainInDirKeydown = (e) => {
            if (e.key === 'Escape') {
                dirSuggestions.value = [];
            }
        };

        const onMainOutFileKeydown = (e) => {
            if (e.key === 'Escape') {
                fileSuggestions.value = [];
            }
        };

        // Dialog Handlers
        const scrollToSelected = (ulRef, index) => {
            nextTick(() => {
                if (!ulRef.value) return;
                const li = ulRef.value.children[index];
                if (li) {
                    li.scrollIntoView({ block: 'nearest' });
                }
            });
        };

        const openDirDialog = () => {
            // In original: select_file_dialog("search_str", "dir", "dialog1", "select_dir", "inDir");
            // Sets search_str val to inDir val
            dirDialog.search = inDir.value;
            dirDialog.suggestions = [];
            dirDialog.selectedIndex = -1;
            dirDialog.visible = true;
            onDirDialogInput(); // Initial search
        };

        const onDirDialogInput = async () => {
             // autocomp("search_str", "dir")
             // url: "search?path=" + val + "&kind=dir"
             const url = `search?path=${encodeURIComponent(dirDialog.search)}&kind=dir`;
             // Note: In original code, it passes req.term as param1. 
             // And path is $("#" + id).val().
             // When typing, term is the current input.
             const res = await fetchSuggestions(dirDialog.search, 'dir', url);
             dirDialog.suggestions = res;
             dirDialog.selectedIndex = -1;
        };

        const onDirDialogKeydown = (e) => {
            if (e.key === 'Escape') {
                dirDialog.suggestions = [];
                dirDialog.selectedIndex = -1;
                return;
            }
            if (dirDialog.suggestions.length === 0) return;
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                dirDialog.selectedIndex = (dirDialog.selectedIndex + 1) % dirDialog.suggestions.length;
                scrollToSelected(dirListRef, dirDialog.selectedIndex);
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                dirDialog.selectedIndex = (dirDialog.selectedIndex - 1 + dirDialog.suggestions.length) % dirDialog.suggestions.length;
                scrollToSelected(dirListRef, dirDialog.selectedIndex);
            } else if (e.key === 'Enter') {
                if (dirDialog.selectedIndex >= 0 && dirDialog.selectedIndex < dirDialog.suggestions.length) {
                    e.preventDefault();
                    selectDirDialogSuggestion(dirDialog.suggestions[dirDialog.selectedIndex]);
                }
            }
        };

        const selectDirDialogSuggestion = (item) => {
            dirDialog.search = item.value;
            dirDialog.suggestions = [];
            dirDialog.selectedIndex = -1;
            onDirDialogInput();
        };

        const confirmDirDialog = () => {
            inDir.value = dirDialog.search;
            dirDialog.visible = false;
        };


        const openFileDialog = () => {
            fileDialog.search = outFile.value;
            fileDialog.suggestions = [];
            fileDialog.selectedIndex = -1;
            fileDialog.visible = true;
            onFileDialogInput();
        };

        const onFileDialogInput = async () => {
             const url = `search?path=${encodeURIComponent(fileDialog.search)}&kind=file`;
             const res = await fetchSuggestions(fileDialog.search, 'file', url);
             fileDialog.suggestions = res;
             fileDialog.selectedIndex = -1;
        };

        const onFileDialogKeydown = (e) => {
            if (e.key === 'Escape') {
                fileDialog.suggestions = [];
                fileDialog.selectedIndex = -1;
                return;
            }
            if (fileDialog.suggestions.length === 0) return;
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                fileDialog.selectedIndex = (fileDialog.selectedIndex + 1) % fileDialog.suggestions.length;
                scrollToSelected(fileListRef, fileDialog.selectedIndex);
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                fileDialog.selectedIndex = (fileDialog.selectedIndex - 1 + fileDialog.suggestions.length) % fileDialog.suggestions.length;
                scrollToSelected(fileListRef, fileDialog.selectedIndex);
            } else if (e.key === 'Enter') {
                if (fileDialog.selectedIndex >= 0 && fileDialog.selectedIndex < fileDialog.suggestions.length) {
                    e.preventDefault();
                    selectFileDialogSuggestion(fileDialog.suggestions[fileDialog.selectedIndex]);
                }
            }
        };

        const selectFileDialogSuggestion = (item) => {
            fileDialog.search = item.value;
            fileDialog.suggestions = [];
            fileDialog.selectedIndex = -1;
            onFileDialogInput();
        };

        const confirmFileDialog = () => {
            outFile.value = fileDialog.search;
            fileDialog.visible = false;
        };


        // Settings Logic
        const openSettingDialog = async () => {
            try {
                const res = await fetch('config/setting.json');
                const data = await res.json();
                settingDialog.version = data.version;
                
                // Transform for UI
                settingDialog.items = data.setting_list.map(item => {
                    const newItem = { ...item };
                    if (newItem.type === 'textarea') {
                        newItem.valueStr = JSON.stringify(newItem.value, null, 2);
                    }
                    // For checkbox, value is already boolean in JSON usually, 
                    // but in original code it checks for "on".
                    // Let's assume standard boolean or check original json.
                    // Original: if (s["setting_list"][i].value == true) ...
                    return newItem;
                });
                
                settingDialog.visible = true;
            } catch (e) {
                console.error("Failed to load settings", e);
                showMsgDialog("設定の読み込みに失敗しました");
            }
        };

        const submitSetting = () => {
            let isError = false;
            const newSettings = settingDialog.items.map(item => {
                const newItem = { ...item };
                // Handle textarea parsing
                if (newItem.type === 'textarea') {
                    try {
                        newItem.value = JSON.parse(newItem.valueStr);
                    } catch (e) {
                        isError = true;
                        alert("JSON Parse Error: " + e.message + "\n" + newItem.valueStr);
                    }
                    delete newItem.valueStr;
                }
                return newItem;
            });

            if (isError) return;

            const jsonObj = {
                version: settingDialog.version,
                setting_list: newSettings
            };
            
            const jsonString = JSON.stringify(jsonObj);
            sendMessage("setting:" + jsonString);
            settingDialog.visible = false;
        };

        const saveSetting = async () => {
            // Get current settings from file (or state?)
            // Original code fetches file again.
            try {
                const res = await fetch('config/setting.json');
                const json = await res.json();
                const jsonData = JSON.stringify(json, null, 2);
                
                const opts = {
                    suggestedName: 'setting.json',
                    types: [{
                        description: 'Text file',
                        accept: { 'text/plain': ['.json'] },
                    }],
                };
                // File System Access API
                if (window.showSaveFilePicker) {
                    const saveHandle = await window.showSaveFilePicker(opts);
                    const writable = await saveHandle.createWritable();
                    await writable.write(jsonData);
                    await writable.close();
                } else {
                    // Fallback
                    const blob = new Blob([jsonData], { type: "text/plain" });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement("a");
                    a.href = url;
                    a.download = "setting.json";
                    a.click();
                }
            } catch (e) {
                console.error("Save setting failed", e);
            }
        };

        const loadSetting = async () => {
             if (window.showOpenFilePicker) {
                 try {
                    const [fileHandle] = await window.showOpenFilePicker();
                    const file = await fileHandle.getFile();
                    const jsonData = await file.text();
                    sendMessage("setting:" + jsonData);
                 } catch (e) {
                     console.error(e);
                 }
             } else {
                 alert("Your browser does not support File System Access API.");
             }
        };


        const handleClickOutside = (event) => {
            if (mainInDirRef.value && !mainInDirRef.value.contains(event.target)) {
                dirSuggestions.value = [];
            }
            if (mainOutFileRef.value && !mainOutFileRef.value.contains(event.target)) {
                fileSuggestions.value = [];
            }
        };

        // Lifecycle
        onMounted(() => {
            serverConnect("ws://localhost:42001/wsserver");
            
            document.addEventListener('click', handleClickOutside);

            // Adjust height
            const updateOutareaHeight = () => {
                const header = document.querySelector('.app-header');
                const menu = document.querySelector('.menu');
                const inputArea = document.querySelector('.input-area');
                
                const headerHeight = header ? header.offsetHeight : 0;
                const menuHeight = menu ? menu.offsetHeight : 0;
                const inputAreaHeight = inputArea ? inputArea.offsetHeight : 0;
                const totalUsedHeight = headerHeight + menuHeight + inputAreaHeight + 40; 
                
                if (outarea.value) {
                    const newHeight = window.innerHeight - totalUsedHeight;
                    outarea.value.style.height = Math.max(200, newHeight) + 'px';
                }
            };

            nextTick(() => {
                updateOutareaHeight();
            });
            window.addEventListener('resize', updateOutareaHeight);
        });

        onBeforeUnmount(() => {
            document.removeEventListener('click', handleClickOutside);
        });

        return {
            inDir, outFile, logs, outarea, hasExecuted, dirListRef, fileListRef,
            mainInDirRef, mainOutFileRef,
            msgDialog, dirDialog, fileDialog, settingDialog,
            dirSuggestions, fileSuggestions,
            // methods
            exec, stop, openSettingDialog, saveSetting, loadSetting, openFile,
            openDirDialog, openFileDialog,
            closeMsgDialog, submitSetting,
            confirmDirDialog, confirmFileDialog,
            // autocomplete handlers
            onInputDir, selectDirSuggestion, onMainInDirKeydown,
            onInputFile, selectFileSuggestion, onMainOutFileKeydown,
            onDirDialogInput, selectDirDialogSuggestion, onDirDialogKeydown,
            onFileDialogInput, selectFileDialogSuggestion, onFileDialogKeydown,
            onScroll
        };
    }
}).mount('#app');
