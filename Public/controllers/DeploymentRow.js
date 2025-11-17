// DeploymentRow Controller
// Manages client-side state for DeploymentRow components

class DeploymentRow {
    
    // The framework passes the component's root <tr> element
    constructor(element) {
        this.rowElement = element;
        this.errorRowElement = null;
        this.timer = null;
        
        const id = this.rowElement.getAttribute('mist-id');
        console.log(`[DeploymentRow] Constructor called for ${id?.substring(0, 8)}`);
        
        // The controller is now self-contained and manages its own state
        this.setupErrorToggle();
        this.setupLiveDuration();
    }
    
    setupErrorToggle() {
        const errorMessage = this.rowElement.dataset.errorMessage;
        const button = this.rowElement.querySelector('.status-badge-failed-expandable');
        
        if (!errorMessage || !button) return;
        
        const id = this.rowElement.getAttribute('mist-id');
        console.log(`[DeploymentRow] Setting up error toggle for ${id?.substring(0, 8)}`);
        
        // 1. Create and inject the error row
        this.errorRowElement = this.createErrorRow(errorMessage);
        this.rowElement.after(this.errorRowElement);
        
        // 2. Add listener
        button.addEventListener('click', (e) => {
            e.preventDefault();
            this.errorRowElement.classList.toggle('deployment-error-expanded');
        });
    }
    
    setupLiveDuration() {
        const liveDurationElement = this.rowElement.querySelector('.deployment-live-duration');
        if (!liveDurationElement) return;
        
        const id = this.rowElement.getAttribute('mist-id');
        console.log(`[DeploymentRow] Setting up live duration timer for ${id?.substring(0, 8)}`);
        
        // Get server's startedAt timestamp from data attribute
        const startedAtStr = this.rowElement.dataset.startedAt;
        console.log(`[DeploymentRow] startedAt from server: "${startedAtStr}"`);
        
        let startedAt;
        if (startedAtStr) {
            // Check if it's a numeric Swift TimeInterval (seconds since 2001-01-01)
            const numericValue = parseFloat(startedAtStr);
            if (!isNaN(numericValue) && numericValue > 0 && numericValue < 1e10) {
                // Convert Swift TimeInterval to Unix timestamp
                // Swift reference date: 2001-01-01 00:00:00 UTC = 978307200 Unix seconds
                startedAt = numericValue + 978307200;
                console.log(`[DeploymentRow] Converted Swift TimeInterval to Unix: ${new Date(startedAt * 1000).toISOString()}`);
            } else {
                // Try parsing as ISO 8601 or standard date format
                let parsed = Date.parse(startedAtStr);
                
                // If that fails, try adding 'Z' for UTC
                if (isNaN(parsed) && !startedAtStr.includes('Z') && !startedAtStr.includes('+')) {
                    parsed = Date.parse(startedAtStr + 'Z');
                }
                
                if (isNaN(parsed)) {
                    console.warn(`[DeploymentRow] Failed to parse date "${startedAtStr}", using current time`);
                    startedAt = Date.now() / 1000;
                } else {
                    startedAt = parsed / 1000;
                    console.log(`[DeploymentRow] Parsed ISO date: ${new Date(parsed).toISOString()}`);
                }
            }
        } else {
            console.warn(`[DeploymentRow] No startedAt attribute, using current time`);
            startedAt = Date.now() / 1000;
        }
        
        // Timer is now scoped to this instance
        this.timer = setInterval(() => {
            // When morphdom replaces running status with success, the .deployment-live-duration element is removed
            const currentElement = this.rowElement.querySelector('.deployment-live-duration');
            if (!currentElement) {
                console.log(`[DeploymentRow] Deployment finished, stopping timer for ${id?.substring(0, 8)}`);
                clearInterval(this.timer);
                this.timer = null;
                return;
            }
            
            const now = Date.now() / 1000;
            const elapsed = now - startedAt;
            currentElement.textContent = elapsed.toFixed(1) + 's';
        }, 100);
    }
    
    createErrorRow(errorMessage) {
        const tr = document.createElement('tr');
        tr.className = 'deployment-error-row';
        tr.innerHTML = `
            <td colspan="6" class="deployment-error-cell">
                <pre class="deployment-error-message"></pre>
            </td>
        `;
        // Set text content separately to avoid XSS issues
        tr.querySelector('.deployment-error-message').textContent = errorMessage;
        return tr;
    }
    
    // Called by Mist's core loop before the element is removed
    destroy() {
        const id = this.rowElement.getAttribute('mist-id');
        console.log(`[DeploymentRow] Destroy called for ${id?.substring(0, 8)}`);
        
        // Clean up any "external" elements we created
        if (this.errorRowElement) {
            console.log(`[DeploymentRow] Removing error row for ${id?.substring(0, 8)}`);
            this.errorRowElement.remove();
        }
        
        // Clean up timers
        if (this.timer) {
            console.log(`[DeploymentRow] Clearing timer for ${id?.substring(0, 8)}`);
            clearInterval(this.timer);
            this.timer = null;
        }
    }
}

// Expose to global window for Mist framework
window.DeploymentRow = DeploymentRow;

