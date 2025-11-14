// Move this file (mist.js) to: /Public 

class MistSocket {
    
    constructor() {

        this.socket = null;
        
        this.timer = null;
        this.initialDelay = 1000;
        this.interval = 5000;
        
        document.addEventListener('visibilitychange', () => this.visibilityChange());
        window.addEventListener('online', () => this.connect());
        document.addEventListener('click', (event) => this.handleAction(event));
    }

    subscribeToPageComponents() {
        
        console.log("subscribing to server components...");
        
        const uniqueComponents = new Set();
        
        // Subscribe to existing components
        document.querySelectorAll('[mist-component]').forEach(element => {
            
            const component = element.getAttribute('mist-component');
            
            if (component) {
                uniqueComponents.add(component);
            }
        });
        
        // Subscribe to components that containers accept (even if they don't exist yet)
        document.querySelectorAll('[mist-container]').forEach(container => {
            
            const acceptedComponents = container.getAttribute('mist-container');
            
            if (acceptedComponents) {
                acceptedComponents.split(',').forEach(component => {
                    const trimmed = component.trim();
                    if (trimmed) {
                        uniqueComponents.add(trimmed);
                    }
                });
            }
        });
        
        uniqueComponents.forEach(component => {
            this.subscribe(component);
        });
    }
    
    subscribe(component) {
        
        if (this.isConnected()) {
            
            const message = {
                subscribe: {
                    component: component
                }
            };
            
            this.socket.send(JSON.stringify(message));
        }
    }
    
    handleAction(event) {
        
        const target = event.target.closest('[mist-action]');
        
        if (!target) return;
        
        const actionName = target.getAttribute('mist-action');
        console.log(`[DEBUG] Action clicked: '${actionName}'`);
        
        // 1. Find component, but ID is now optional
        const componentElement = target.closest('[mist-component]');
        console.log(`[DEBUG] Component element:`, componentElement);
        
        if (!componentElement || !actionName) {
            console.log(`[DEBUG] Early return - componentElement:`, componentElement, 'actionName:', actionName);
            return;
        }
        
        const componentName = componentElement.getAttribute('mist-component');
        // 2. ID can now be null, which is valid
        const componentId = componentElement.getAttribute('mist-id');
        
        // 3. Only require componentName. componentId is optional.
        if (!componentName) return;
        
        if (this.isConnected()) {
            
            const message = {
                action: {
                    component: componentName,
                    id: componentId, // Will correctly send `id: null` if not found
                    action: actionName
                }
            };
            
            this.socket.send(JSON.stringify(message));
            
            // 4. Update log message to handle null ID
            const idLog = componentId ? componentId.substring(0, 8) : 'null';
            console.log(`Client action sent: '${actionName}' on '${componentName}' (${idLog})`);
        }
    }
    
    isConnected() { return this.socket?.readyState === WebSocket.OPEN; }
    isConnecting() { return this.socket?.readyState === WebSocket.CONNECTING; }
    
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
                
                if (data.update) {
                    const { component, id, html } = data.update;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    elements.forEach(element => {
                        element.outerHTML = html;
                    });
                    
                    console.log(`Server update message: '${component}' (${id ? id.substring(0, 8) : 'null'})`);
                }
                else if (data.create) {
                    const { component, id, html } = data.create;
                    const existingElements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    // If component already exists, treat as update
                    if (existingElements.length > 0) {
                        existingElements.forEach(element => {
                            element.outerHTML = html;
                        });
                        console.log(`Server create message (treated as update): '${component}' (${id ? id.substring(0, 8) : 'null'})`);
                    } else {
                        // Find container that accepts this component
                        const containers = document.querySelectorAll('[mist-container]');
                        
                        for (const container of containers) {
                            const acceptedComponents = container.getAttribute('mist-container').split(',').map(c => c.trim());
                            
                            if (acceptedComponents.includes(component)) {
                                // Check for custom insertion position (default: 'beforeend' to append)
                                const insertPosition = container.getAttribute('mist-insert-position') || 'beforeend';
                                container.insertAdjacentHTML(insertPosition, html);
                                console.log(`Server create message: '${component}' (${id ? id.substring(0, 8) : 'null'})`);
                                break;
                            }
                        }
                    }
                }
                else if (data.delete) {
                    const { component, id } = data.delete;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    elements.forEach(element => {
                        element.remove();
                    });
                    
                    console.log(`Server delete message: '${component}' (${id ? id.substring(0, 8) : 'null'})`);
                }
                else if (data.actionResult) {
                    const { component, id, action, result, message } = data.actionResult;
                    const isSuccess = result.success !== undefined;
                    const resultType = isSuccess ? 'SUCCESS' : 'FAILURE';
                    
                    console.log(`Action result [${resultType}]: '${action}' on '${component}' (${id.substring(0, 8)}) - ${message}`);
                }
                else if (data.text) {
                    const { message } = data.text;
                    console.log(`Server message: '${message}'`);
                }
                else {
                    console.log(`Unhandled server message (RAW): '${event.data}'`);
                }
            }
            catch (error) {
                console.error(`Error parsing server message: '${error}'`);
            }
        };
        
        this.socket.onclose = () => {

            if (this.timer) return
                
            console.log("WS: ... closed -> Connect in 1s ...");
            
            setTimeout(() => {
                this.connect();
                
                this.timer = setInterval(() => {
                    this.connect();
                },
                this.interval);
            },
            this.initialDelay);
        };
    }
    
    // Helper function to build component selector
    buildComponentSelector(component, id) {
        if (id) {
            return `[mist-component="${component}"][mist-id="${id}"]`;
        } else {
            return `[mist-component="${component}"]`;
        }
    }

    visibilityChange() {
        if (document.visibilityState === "visible") {
            console.log('visibilityState === "visible" -> calling connect()')
            this.connect();
        }
    }
}

// Wait for the DOM to be fully loaded before executing the code
document.addEventListener('DOMContentLoaded', function () {
    window.ws = new MistSocket();
    window.ws.connect()
});
