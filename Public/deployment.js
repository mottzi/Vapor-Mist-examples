// Deployment-specific JavaScript functionality

class DeploymentManager {
    constructor() {
        this.startLiveDurationUpdates();
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
        document.querySelectorAll('.live-duration').forEach(element => {
            // Find the deployment row
            const row = element.closest('tr[mist-component="DeploymentRow"]');
            if (row) {
                // Get or create the start timestamp for this row
                let startedAt = row.dataset.liveStartTime;
                if (!startedAt) {
                    // First time seeing this row, record the current time
                    startedAt = Date.now() / 1000; // Convert to seconds
                    row.dataset.liveStartTime = startedAt;
                }
                const now = Date.now() / 1000;
                const elapsed = now - parseFloat(startedAt);
                element.textContent = elapsed.toFixed(1) + 's';
            }
        });
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => new DeploymentManager());
} else {
    new DeploymentManager();
}
