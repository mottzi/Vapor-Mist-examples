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
        // Process all deployment rows that have error messages
        document.querySelectorAll('tr.deployment-row[data-has-error="true"]').forEach(deploymentRow => {
            // Check if error row already exists
            const nextRow = deploymentRow.nextElementSibling;
            const hasErrorRow = nextRow && nextRow.classList.contains('deployment-error-row');
            
            if (!hasErrorRow) {
                // Create the error row
                const errorMessage = deploymentRow.dataset.errorMessage;
                if (errorMessage) {
                    const errorRow = this.createErrorRow(errorMessage);
                    deploymentRow.after(errorRow);
                }
            }
        });

        // Add click listeners to all expandable failed badges
        document.querySelectorAll('.status-badge-failed-expandable').forEach(button => {
            // Create a unique identifier to track if listener is already attached
            if (button.dataset.listenerAttached) return;
            button.dataset.listenerAttached = 'true';

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

    createErrorRow(errorMessage) {
        const tr = document.createElement('tr');
        tr.className = 'deployment-error-row';
        tr.innerHTML = `
            <td colspan="6" class="deployment-error-cell">
                <div class="deployment-error-container">
                    <div class="deployment-error-label">Error Details:</div>
                    <pre class="deployment-error-message"></pre>
                </div>
            </td>
        `;
        // Set text content separately to avoid XSS issues
        tr.querySelector('.deployment-error-message').textContent = errorMessage;
        return tr;
    }

    observeNewDeployments() {
        // Watch for new deployment rows being added/removed by Mist
        const observer = new MutationObserver((mutations) => {
            let shouldUpdate = false;
            
            mutations.forEach(mutation => {
                // Handle added nodes
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === 1 && node.classList?.contains('deployment-row')) {
                        shouldUpdate = true;
                    }
                });
                
                // Handle removed nodes - clean up orphaned error rows
                mutation.removedNodes.forEach(node => {
                    if (node.nodeType === 1 && node.classList?.contains('deployment-row')) {
                        // If this was a deployment row with an error, remove its error row too
                        const nextSibling = mutation.nextSibling;
                        if (nextSibling && nextSibling.classList?.contains('deployment-error-row')) {
                            nextSibling.remove();
                        }
                    }
                });
            });
            
            if (shouldUpdate) {
                this.setupErrorToggleListeners();
            }
        });

        const tbody = document.querySelector('.deployment-tbody');
        if (tbody) {
            observer.observe(tbody, {
                childList: true,
                subtree: false
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
