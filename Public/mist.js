class MistSocket {
    
    constructor() {
        this.socket = null;
        this.timer = null;
        this.initialDelay = 1000;
        this.interval = 5000;
        
        // [NEW] Store client state for components (persistence across server updates)
        this.componentStates = new Map(); 
        
        document.addEventListener('visibilitychange', () => this.visibilityChange());
        window.addEventListener('online', () => this.connect());
        
        // [NEW] Delegated Event Listener for Client Logic
        document.addEventListener('click', (event) => {
            // 1. Check for Server Actions
            this.handleAction(event);
            // 2. Check for Client Logic
            this.handleClientLogic(event);
        });
        
        // [NEW] Initialize existing components on load
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.hydrateAll());
        } else {
            // DOM already loaded, hydrate immediately
            this.hydrateAll();
        }
    }

    // [NEW] Logic Handler
    handleClientLogic(event) {
        const target = event.target.closest('[mist-on-click]');
        if (!target) return;

        const componentEl = target.closest('[mist-state]');
        if (!componentEl) return;

        const actionName = target.getAttribute('mist-on-click');
        const logicJSON = componentEl.getAttribute('mist-logic');
        const stateJSON = componentEl.getAttribute('mist-state');
        
        if (!logicJSON || !stateJSON) return;

        // getAttribute() automatically unescapes HTML entities
        const logic = JSON.parse(logicJSON);
        const state = JSON.parse(stateJSON);
        const funcBody = logic[actionName];

        if (funcBody) {
            event.preventDefault();
            // Execute logic against state
            try {
                // Create a proxy to detect changes
                const stateProxy = new Proxy(state, {
                    set: (obj, prop, value) => {
                        obj[prop] = value;
                        return true;
                    }
                });
                
                // Run function
                (new Function(funcBody)).call(stateProxy);
                
                // Update DOM
                this.updateComponentUI(componentEl, stateProxy);
                
                // Save new state to DOM attribute and Memory
                const newStateStr = JSON.stringify(stateProxy);
                componentEl.setAttribute('mist-state', newStateStr);
                
                const id = componentEl.getAttribute('mist-id');
                if (id) this.componentStates.set(id, newStateStr);
                
            } catch (e) {
                console.error("Mist Logic Error:", e);
            }
        }
    }

    // [NEW] UI Updater (Bindings)
    updateComponentUI(element, state) {
        // Handle mist-show (visibility)
        element.querySelectorAll('[mist-show]').forEach(el => {
            const key = el.getAttribute('mist-show');
            el.style.display = state[key] ? '' : 'none';
        });
        
        // Handle mist-class-[className] (css classes)
        element.querySelectorAll('*').forEach(el => {
            Array.from(el.attributes).forEach(attr => {
                if (attr.name.startsWith('mist-class-')) {
                    const className = attr.name.replace('mist-class-', '');
                    const key = attr.value;
                    if (state[key]) el.classList.add(className);
                    else el.classList.remove(className);
                }
            });
        });
    }

    // [NEW] Hydrate all interactive components
    hydrateAll() {
        document.querySelectorAll('[mist-state]').forEach(el => {
            try {
                const stateJSON = el.getAttribute('mist-state');
                if (!stateJSON) return;
                // getAttribute() automatically unescapes HTML entities
                const state = JSON.parse(stateJSON);
                this.updateComponentUI(el, state);
            } catch (e) {
                console.error("Mist Hydration Error:", e, el.getAttribute('mist-state'));
            }
        });
    }

    subscribeToPageComponents() {
        console.log("Client: Subscribing to on-page components...");
        const uniqueComponents = new Set();
        
        document.querySelectorAll('[mist-component]').forEach(element => {
            const component = element.getAttribute('mist-component');
            if (component) uniqueComponents.add(component);
        });
        
        document.querySelectorAll('[mist-container]').forEach(container => {
            const acceptedComponents = container.getAttribute('mist-container');
            if (acceptedComponents) {
                acceptedComponents.split(',').forEach(component => {
                    const trimmed = component.trim();
                    if (trimmed) uniqueComponents.add(trimmed);
                });
            }
        });
        
        uniqueComponents.forEach(component => {
            this.subscribe(component);
        });
    }
    
    subscribe(component) {
        if (this.isConnected()) {
            const message = { subscribe: { component: component } };
            this.socket.send(JSON.stringify(message));
        }
    }
    
    handleAction(event) {
        const target = event.target.closest('[mist-action]');
        if (!target) return;
        
        const actionName = target.getAttribute('mist-action');
        const componentElement = target.closest('[mist-component]');
        
        if (!componentElement || !actionName) return;
        
        const componentName = componentElement.getAttribute('mist-component');
        const componentId = componentElement.getAttribute('mist-id');
        
        if (!componentName) return;
        
        if (this.isConnected()) {
            const message = {
                action: {
                    component: componentName,
                    id: componentId, 
                    action: actionName
                }
            };
            this.socket.send(JSON.stringify(message));
            const idLog = componentId ? componentId.substring(0, 8) : 'null';
            console.log(`Action sent: '${actionName}' on '${componentName}' (${idLog})`);
        }
    }
    
    isConnected() { return this.socket?.readyState === WebSocket.OPEN; }
    isConnecting() { return this.socket?.readyState === WebSocket.CONNECTING; }
    
    // [NEW] Helper for morphdom options
    getMorphOptions() {
        return {
            // Help morphdom match tbody elements by mist-id
            getNodeKey: (node) => {
                // For tbody elements with mist-id, use that as the key
                // This ensures morphdom can correctly match the component during updates
                if (node.nodeType === 1 && node.tagName === 'TBODY' && node.hasAttribute && node.hasAttribute('mist-id')) {
                    return node.getAttribute('mist-id');
                }
                // Default: use id attribute if available
                return node.getAttribute && node.getAttribute('id') ? node.getAttribute('id') : null;
            },
            onBeforeElUpdated: (fromEl, toEl) => {
                // PRESERVE STATE:
                // If the element being updated is a Mist component with state,
                // we prioritize the LOCAL state (fromEl) over the SERVER state (toEl),
                // because the server doesn't know about client interactions (expanded/collapsed).
                
                if (fromEl.hasAttribute('mist-state')) {
                    const id = fromEl.getAttribute('mist-id');
                    
                    // 1. Check memory cache first
                    if (id && this.componentStates.has(id)) {
                        const savedState = this.componentStates.get(id);
                        toEl.setAttribute('mist-state', savedState);
                        // Also preserve mist-logic
                        if (fromEl.hasAttribute('mist-logic')) {
                            toEl.setAttribute('mist-logic', fromEl.getAttribute('mist-logic'));
                        }
                    } 
                    // 2. Fallback to DOM attribute
                    else {
                        toEl.setAttribute('mist-state', fromEl.getAttribute('mist-state'));
                        if (fromEl.hasAttribute('mist-logic')) {
                            toEl.setAttribute('mist-logic', fromEl.getAttribute('mist-logic'));
                        }
                    }
                }
                
                // For tbody elements, ensure we preserve the structure
                if (fromEl.tagName === 'TBODY' && toEl.tagName === 'TBODY') {
                    // Ensure mist attributes are preserved
                    if (fromEl.hasAttribute('mist-component')) {
                        toEl.setAttribute('mist-component', fromEl.getAttribute('mist-component'));
                    }
                    if (fromEl.hasAttribute('mist-id')) {
                        toEl.setAttribute('mist-id', fromEl.getAttribute('mist-id'));
                    }
                }
                
                return true;
            },
            onElUpdated: (el) => {
                // Re-run bindings after update
                if (el.hasAttribute('mist-state')) {
                    try {
                        // getAttribute() automatically unescapes HTML entities
                        const state = JSON.parse(el.getAttribute('mist-state'));
                        this.updateComponentUI(el, state);
                    } catch (e) {
                        console.error("Mist State Update Error:", e);
                    }
                }
                
                // For tbody elements, ensure all mist attributes are preserved
                if (el.tagName === 'TBODY' && el.hasAttribute('mist-component')) {
                    // Re-apply UI bindings after morphdom update
                    if (el.hasAttribute('mist-state')) {
                        try {
                            const state = JSON.parse(el.getAttribute('mist-state'));
                            this.updateComponentUI(el, state);
                        } catch (e) {
                            console.error("Mist TBody State Update Error:", e);
                        }
                    }
                }
            },
            // Handle children updates for tbody - ensure rows are properly matched
            onBeforeElChildrenUpdated: (fromEl, toEl) => {
                // For tbody elements, we want to ensure proper row matching
                if (fromEl.tagName === 'TBODY' && toEl.tagName === 'TBODY') {
                    // Let morphdom handle the children update normally
                    return true;
                }
                return true;
            }
        };
    }

    connect() {
        if (this.isConnected() || this.isConnecting()) return;
        if (this.socket) { this.socket.close(); this.socket = null; }
        
        this.socket = new WebSocket('wss://mottzi.de/mist/ws/');
        
        this.socket.onopen = () => {
            if (this.timer) { clearInterval(this.timer); this.timer = null; }
            this.subscribeToPageComponents();
        };
        
        this.socket.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                const morphOpts = this.getMorphOptions(); // Use new options

                if (data.createInstanceComponent) {
                    const { component, id, html } = data.createInstanceComponent;
                    const existingElements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    if (existingElements.length > 0) {
                        existingElements.forEach(element => morphdom(element, html, morphOpts));
                        console.log(`Instance create (treated as patch): '${component}'`);
                    } else {
                        const containers = document.querySelectorAll('[mist-container]');
                        for (const container of containers) {
                            const acceptedComponents = container.getAttribute('mist-container').split(',').map(c => c.trim());
                            if (acceptedComponents.includes(component)) {
                                const insertPosition = container.getAttribute('mist-insert-position') || 'beforeend';
                                
                                // Special handling for table elements: if container is a table and we're inserting tbody,
                                // insert after thead instead of using afterbegin
                                if (container.tagName === 'TABLE' && html.trim().startsWith('<tbody')) {
                                    const thead = container.querySelector('thead');
                                    if (thead) {
                                        thead.insertAdjacentHTML('afterend', html);
                                    } else {
                                        container.insertAdjacentHTML(insertPosition, html);
                                    }
                                } else {
                                    container.insertAdjacentHTML(insertPosition, html);
                                }
                                
                                // [NEW] Hydrate new element - find the component by its attributes
                                const newEl = container.querySelector(`[mist-component="${component}"][mist-id="${id}"]`);
                                if(newEl && newEl.hasAttribute('mist-state')) {
                                    try {
                                        // getAttribute() automatically unescapes HTML entities
                                        this.updateComponentUI(newEl, JSON.parse(newEl.getAttribute('mist-state')));
                                    } catch (e) {
                                        console.error("Mist Hydration Error on new element:", e);
                                    }
                                }
                                console.log(`Instance create: '${component}'`);
                                break;
                            }
                        }
                    }
                }
                else if (data.updateInstanceComponent) {
                    const { component, id, html } = data.updateInstanceComponent;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    if (elements.length === 0) {
                        // Element doesn't exist - treat as create and insert it
                        console.log(`Instance patch: '${component}' (id: ${id?.substring(0, 8)}) - element not found, treating as create`);
                        const containers = document.querySelectorAll('[mist-container]');
                        for (const container of containers) {
                            const acceptedComponents = container.getAttribute('mist-container').split(',').map(c => c.trim());
                            if (acceptedComponents.includes(component)) {
                                const insertPosition = container.getAttribute('mist-insert-position') || 'beforeend';
                                
                                // Special handling for table elements: if container is a table and we're inserting tbody,
                                // insert after thead instead of using afterbegin
                                let insertTarget = container;
                                if (container.tagName === 'TABLE' && html.trim().startsWith('<tbody')) {
                                    const thead = container.querySelector('thead');
                                    if (thead) {
                                        insertTarget = thead;
                                        insertTarget.insertAdjacentHTML('afterend', html);
                                    } else {
                                        container.insertAdjacentHTML(insertPosition, html);
                                    }
                                } else {
                                    container.insertAdjacentHTML(insertPosition, html);
                                }
                                
                                // Hydrate new element
                                const newEl = container.querySelector(`[mist-component="${component}"][mist-id="${id}"]`);
                                if(newEl && newEl.hasAttribute('mist-state')) {
                                    try {
                                        this.updateComponentUI(newEl, JSON.parse(newEl.getAttribute('mist-state')));
                                    } catch (e) {
                                        console.error("Mist Hydration Error on new element:", e);
                                    }
                                }
                                console.log(`Instance patch (created): '${component}' (id: ${id?.substring(0, 8)})`);
                                break;
                            }
                        }
                    } else {
                        elements.forEach(element => {
                            console.log(`Instance patch: '${component}' (id: ${id?.substring(0, 8)}), element:`, element.tagName, element.className);
                            // Store state before morphdom update
                            const stateBefore = element.hasAttribute('mist-state') ? element.getAttribute('mist-state') : null;
                            try {
                                morphdom(element, html, morphOpts);
                                // Verify state was preserved after update
                                if (stateBefore && !element.hasAttribute('mist-state')) {
                                    console.warn(`State lost during morphdom update for ${component} ${id?.substring(0, 8)}`);
                                    element.setAttribute('mist-state', stateBefore);
                                    // Re-apply UI bindings
                                    try {
                                        this.updateComponentUI(element, JSON.parse(stateBefore));
                                    } catch (e) {
                                        console.error("Mist State Re-apply Error:", e);
                                    }
                                }
                            } catch (e) {
                                console.error(`Morphdom error for ${component} ${id?.substring(0, 8)}:`, e);
                            }
                        });
                    }
                }
                else if (data.deleteInstanceComponent) {
                    const { component, id } = data.deleteInstanceComponent;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    elements.forEach(element => element.remove());
                    // [NEW] cleanup memory
                    if (this.componentStates.has(id)) this.componentStates.delete(id);
                    console.log(`Instance delete: '${component}'`);
                }
                else if (data.updateQueryComponent) {
                    const { component, html } = data.updateQueryComponent;
                    const existingElements = document.querySelectorAll(this.buildComponentSelector(component, null));
                    
                    if (existingElements.length > 0) {
                        existingElements.forEach(element => morphdom(element, html, morphOpts));
                    } else {
                        const containers = document.querySelectorAll('[mist-container]');
                        for (const container of containers) {
                            const acceptedComponents = container.getAttribute('mist-container').split(',').map(c => c.trim());
                            if (acceptedComponents.includes(component)) {
                                const insertPosition = container.getAttribute('mist-insert-position') || 'beforeend';
                                container.insertAdjacentHTML(insertPosition, html);
                                break;
                            }
                        }
                    }
                }
                else if (data.deleteQueryComponent) {
                    const { component } = data.deleteQueryComponent;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, null));
                    elements.forEach(element => element.remove());
                }
                else if (data.actionResult) {
                    const { component, id, action, result, message } = data.actionResult;
                    const isSuccess = result.success !== undefined;
                    const resultType = isSuccess ? '✅' : '❌';
                    console.log(`Action result [${resultType}]: '${action}' - ${message}`);
                }
                else if (data.text) {
                    console.log(`Server message: '${data.text.message}'`);
                }
            }
            catch (error) {
                console.error(`Error parsing server message: '${error}'`, error);
            }
        };
        
        this.socket.onclose = () => {
            if (this.timer) return;
            console.log("WS: ... closed -> Connect in 1s ...");
            setTimeout(() => {
                this.connect();
                this.timer = setInterval(() => { this.connect(); }, this.interval);
            }, this.initialDelay);
        };
    }
    
    buildComponentSelector(component, id) {
        if (id) return `[mist-component="${component}"][mist-id="${id}"]`;
        return `[mist-component="${component}"]`;
    }

    visibilityChange() {
        if (document.visibilityState === "visible") {
            this.connect();
        }
    }
}

// Initialize MistSocket
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
        console.log("Mist: Initializing...");
        window.ws = new MistSocket();
        window.ws.connect();
    });
} else {
    // DOM already loaded
    console.log("Mist: Initializing (DOM already loaded)...");
    window.ws = new MistSocket();
    window.ws.connect();
}
