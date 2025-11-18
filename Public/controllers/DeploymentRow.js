// Deployment-specific JavaScript functionality

class DeploymentManager {
    constructor() {
        this.startLiveDurationUpdates();
        // [REMOVED] this.setupErrorToggleListeners();
        // [REMOVED] this.observeNewDeployments();
    }

    startLiveDurationUpdates() {
        // Update live duration displays every 100ms (0.1 seconds)
        setInterval(() => {
            this.updateLiveDurations();
        }, 100);

        // Also update immediately on page load
        this.updateLiveDurations();
    }

    updateLiveDurations() {
        document.querySelectorAll('.deployment-live-duration').forEach(element => {
            // [CHANGED] Find closest row, might be within a tbody now
            const row = element.closest('tr.deployment-row');
            if (row) {
                // Check if the element is still in the DOM (morphdom might have removed it)
                if (!document.contains(element)) return;
                
                let startedAt = row.dataset.liveStartTime;
                if (!startedAt) {
                    // Try to get startedAt from the tbody's data attribute or from the server-rendered time
                    const tbody = row.closest('tbody[mist-component="DeploymentRow"]');
                    if (tbody) {
                        // We could parse from the time display, but for now just use current time
                        startedAt = Date.now() / 1000;
                    } else {
                        startedAt = Date.now() / 1000;
                    }
                    row.dataset.liveStartTime = startedAt;
                }
                const now = Date.now() / 1000;
                const elapsed = now - parseFloat(startedAt);
                // Only update if element still exists and is visible
                if (element.parentElement && element.parentElement.classList.contains('deployment-duration-running')) {
                    element.textContent = elapsed.toFixed(1) + 's';
                }
            }
        });
    }
    
    // [REMOVED] setupErrorToggleListeners()
    // [REMOVED] createErrorRow()
    // [REMOVED] observeNewDeployments()
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => new DeploymentManager());
} else {
    new DeploymentManager();
}
