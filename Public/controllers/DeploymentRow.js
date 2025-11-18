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
                let startedAt = row.dataset.liveStartTime;
                if (!startedAt) {
                    startedAt = Date.now() / 1000; 
                    row.dataset.liveStartTime = startedAt;
                }
                const now = Date.now() / 1000;
                const elapsed = now - parseFloat(startedAt);
                element.textContent = elapsed.toFixed(1) + 's';
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
