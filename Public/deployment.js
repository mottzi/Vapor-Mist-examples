// Deployment-specific JavaScript functionality

class DeploymentManager {
    constructor() {
        this.startLiveDurationUpdates();
        this.setupErrorToggleListeners();
        this.observeNewDeployments();
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

    setupErrorToggleListeners() {
        // Add click listeners to all expandable failed badges
        document.querySelectorAll('.status-badge-failed-expandable').forEach(button => {
            // Remove any existing listener to avoid duplicates
            button.replaceWith(button.cloneNode(true));
        });

        // Now add fresh listeners
        document.querySelectorAll('.status-badge-failed-expandable').forEach(button => {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                const deploymentRow = button.closest('tr.deployment-row');
                const errorRow = deploymentRow?.nextElementSibling;
                
                if (errorRow && errorRow.classList.contains('deployment-error-row')) {
                    errorRow.classList.toggle('deployment-error-expanded');
                }
            });
        });
    }

    observeNewDeployments() {
        // Watch for new deployment rows being added by Mist
        const observer = new MutationObserver(() => {
            this.setupErrorToggleListeners();
        });

        const tbody = document.querySelector('.deployment-tbody');
        if (tbody) {
            observer.observe(tbody, {
                childList: true,
                subtree: true
            });
        }
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => new DeploymentManager());
} else {
    new DeploymentManager();
}
