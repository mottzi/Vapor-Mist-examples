class DeploymentRow {
    
    // The framework passes the component's root <tr> element
    constructor(element) {
        this.rowElement = element;
        this.errorRowElement = null;
        this.timer = null;
        
        // The controller is now self-contained and manages its own state
        this.setupErrorToggle();
        this.setupLiveDuration();
    }
    
    setupErrorToggle() {
        const errorMessage = this.rowElement.dataset.errorMessage;
        const button = this.rowElement.querySelector('.status-badge-failed-expandable');
        
        // Early return if no error or already setup
        if (!errorMessage || !button) return;
        if (button.dataset.listenerAttached) return;
        
        const id = this.rowElement.getAttribute('mist-id');
        console.log(`[DeploymentRow] Setting up error toggle for ${id?.substring(0, 8)}`);
        
        // 1. Create and inject the error row (only if it doesn't exist)
        if (!this.errorRowElement) {
            this.errorRowElement = this.createErrorRow(errorMessage);
            this.rowElement.after(this.errorRowElement);
        }
        
        // 2. Add listener (mark to prevent duplicate listeners)
        button.dataset.listenerAttached = 'true';
        button.addEventListener('click', (e) => {
            e.preventDefault();
            this.errorRowElement.classList.toggle('deployment-error-expanded');
        });
    }
    
    setupLiveDuration() {
        const liveDurationElement = this.rowElement.querySelector('.deployment-live-duration');
        if (!liveDurationElement) return;
        
        // Convert Swift TimeInterval (seconds since 2001-01-01) to Unix timestamp
        // Swift reference date: 2001-01-01 00:00:00 UTC = 978307200 Unix seconds
        const swiftInterval = parseFloat(this.rowElement.dataset.startedAt);
        const startedAt = !isNaN(swiftInterval) ? swiftInterval + 978307200 : Date.now() / 1000;
        
        const id = this.rowElement.getAttribute('mist-id');
        console.log(`[DeploymentRow] Setting up live duration timer for ${id?.substring(0, 8)}`);

        
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
    
    // Called by Mist after morphdom patches the element
    update() {
        // Re-setup error toggle in case deployment just became failed
        this.setupErrorToggle();
    }
    
    // Called by Mist's core loop before the element is removed
    destroy() {
        // Clean up any "external" elements we created
        if (this.errorRowElement) {
            this.errorRowElement.remove();
        }
        
        // Clean up timers
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
    }
}

// Expose to global window for Mist framework
window.DeploymentRow = DeploymentRow;

