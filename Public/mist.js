// Move this file (mist.js) to: /Public 

class MistSocket {
    
    constructor() {

        this.socket = null;
        
        this.timer = null;
        this.initialDelay = 1000;
        this.interval = 5000;
        
        this.activeControllers = new Map(); // Stores "controllerName-componentId" -> controllerInstance
        
        document.addEventListener('visibilitychange', () => this.visibilityChange());
        window.addEventListener('online', () => this.connect());
        document.addEventListener('click', (event) => this.handleAction(event));
    }

    subscribeToPageComponents() {
        
        console.log("Client: Subscribing to on-page components...");
        
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
    
    // NEW: Boots controllers for elements that declare them
    bootDeclaredControllers() {
        const elements = document.querySelectorAll('[mist-controller]');
        console.log(`[Mist] Booting ${elements.length} declared controller(s)`);
        elements.forEach(element => {
            this.bootControllerForElement(element);
        });
    }
    
    // NEW: Manages the lifecycle of a single controller
    bootControllerForElement(element) {
        const controllerName = element.getAttribute('mist-controller');
        const componentId = element.getAttribute('mist-id');
        
        if (!controllerName || !componentId) {
            console.log(`[Mist] Skipping boot: missing controller name or component ID`);
            return;
        }
        
        const key = `${controllerName}-${componentId}`;
        
        if (this.activeControllers.has(key)) {
            console.log(`[Mist] Controller already booted: '${controllerName}' for ${componentId.substring(0, 8)}`);
            return; // Already booted
        }
        
        // Find the declared class on the global `window` object
        const ControllerClass = window[controllerName]; 
        
        if (ControllerClass) {
            try {
                console.log(`[Mist] Booting controller: '${controllerName}' for ${componentId.substring(0, 8)}`);
                // Create an instance, passing the component's root element
                const instance = new ControllerClass(element); 
                this.activeControllers.set(key, instance);
                console.log(`[Mist] ✓ Controller booted: '${controllerName}' for ${componentId.substring(0, 8)}`);
            } catch (e) {
                console.error(`[Mist] ✗ Failed to boot controller: ${controllerName}`, e);
            }
        } else {
            console.warn(`[Mist] Controller class not found on window: ${controllerName}`);
        }
    }
    
    // NEW: Manages controller cleanup
    destroyControllerForElement(element) {
        const controllerName = element.getAttribute('mist-controller');
        const componentId = element.getAttribute('mist-id');
        
        if (!controllerName || !componentId) return;
        
        const key = `${controllerName}-${componentId}`;
        const instance = this.activeControllers.get(key);
        
        if (instance) {
            console.log(`[Mist] Destroying controller: '${controllerName}' for ${componentId.substring(0, 8)}`);
            if (typeof instance.destroy === 'function') {
                instance.destroy();
            } else {
                console.warn(`[Mist] Controller '${controllerName}' has no destroy() method`);
            }
            this.activeControllers.delete(key);
            console.log(`[Mist] ✓ Controller destroyed: '${controllerName}' for ${componentId.substring(0, 8)}`);
        } else {
            console.log(`[Mist] No active controller found to destroy: '${controllerName}' for ${componentId.substring(0, 8)}`);
        }
    }
    
    handleAction(event) {
        
        const target = event.target.closest('[mist-action]');
        
        if (!target) return;
        
        const actionName = target.getAttribute('mist-action');
        
        // 1. Find component, but ID is now optional
        const componentElement = target.closest('[mist-component]');
        
        if (!componentElement || !actionName) return;
        
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
            console.log(`Action sent: '${actionName}' on '${componentName}' (${idLog})`);
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
            
            // NEW: Boot controllers AFTER the first connection/subscription
            this.bootDeclaredControllers();
        };
        
        this.socket.onmessage = (event) => {
            try {
                
                const data = JSON.parse(event.data);
                
                // Instance-based component messages (with ID)
                if (data.createInstanceComponent) {
                    const { component, id, html } = data.createInstanceComponent;
                    const existingElements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    // If component already exists, treat as update
                    if (existingElements.length > 0) {
                        existingElements.forEach(element => {
                            morphdom(element, html);
                            // NEW: Boot controller after morphing, in case it was just added
                            this.bootControllerForElement(element);
                        });
                        console.log(`Instance create (treated as patch): '${component}' (${id.substring(0, 8)})`);
                    } else {
                        // Find container that accepts this component
                        const containers = document.querySelectorAll('[mist-container]');
                        
                        for (const container of containers) {
                            const acceptedComponents = container.getAttribute('mist-container').split(',').map(c => c.trim());
                            
                            if (acceptedComponents.includes(component)) {
                                // Check for custom insertion position (default: 'beforeend' to append)
                                const insertPosition = container.getAttribute('mist-insert-position') || 'beforeend';
                                container.insertAdjacentHTML(insertPosition, html);
                                console.log(`Instance create: '${component}' (${id.substring(0, 8)})`);
                                
                                // NEW: After creating the element, boot its controller
                                const newElement = document.querySelector(this.buildComponentSelector(component, id));
                                if (newElement) {
                                    this.bootControllerForElement(newElement);
                                }
                                break;
                            }
                        }
                    }
                }
                else if (data.updateInstanceComponent) {
                    const { component, id, html } = data.updateInstanceComponent;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    elements.forEach(element => {
                        morphdom(element, html);
                        // NEW: Boot controller after morphing, in case it was just added
                        this.bootControllerForElement(element);
                    });
                    
                    console.log(`Instance patch: '${component}' (${id.substring(0, 8)})`);
                }
                else if (data.deleteInstanceComponent) {
                    const { component, id } = data.deleteInstanceComponent;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, id));
                    
                    elements.forEach(element => {
                        // NEW: Clean up the controller before removing the element
                        this.destroyControllerForElement(element);
                        element.remove();
                    });
                    
                    console.log(`Instance delete: '${component}' (${id.substring(0, 8)})`);
                }
                // Query-based component messages (no ID)
                else if (data.updateQueryComponent) {
                    const { component, html } = data.updateQueryComponent;
                    const existingElements = document.querySelectorAll(this.buildComponentSelector(component, null));
                    
                    // If component already exists, replace it
                    if (existingElements.length > 0) {
                        existingElements.forEach(element => {
                            morphdom(element, html);
                        });
                        console.log(`Query patch (replaced): '${component}'`);
                    } else {
                        // Find container that accepts this component
                        const containers = document.querySelectorAll('[mist-container]');
                        
                        for (const container of containers) {
                            const acceptedComponents = container.getAttribute('mist-container').split(',').map(c => c.trim());
                            
                            if (acceptedComponents.includes(component)) {
                                // Check for custom insertion position (default: 'beforeend' to append)
                                const insertPosition = container.getAttribute('mist-insert-position') || 'beforeend';
                                container.insertAdjacentHTML(insertPosition, html);
                                console.log(`Query update (created): '${component}'`);
                                break;
                            }
                        }
                    }
                }
                else if (data.deleteQueryComponent) {
                    const { component } = data.deleteQueryComponent;
                    const elements = document.querySelectorAll(this.buildComponentSelector(component, null));
                    
                    elements.forEach(element => {
                        element.remove();
                    });
                    
                    console.log(`Query delete: '${component}'`);
                }
                else if (data.actionResult) {
                    const { component, id, action, result, message } = data.actionResult;
                    const isSuccess = result.success !== undefined;
                    const resultType = isSuccess ? '✅' : '❌';
                    const idLog = id ? id.substring(0, 8) : 'null';
                    
                    console.log(`Action result [${resultType}]: '${action}' on '${component}' (${idLog}) - ${message}`);
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
