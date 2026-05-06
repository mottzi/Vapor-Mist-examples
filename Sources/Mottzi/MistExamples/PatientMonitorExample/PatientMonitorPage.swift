import Vapor
import Elementary
import Mist

struct PatientMonitorPage: HTMLDocument {
    let title = "Live Patient Monitor"
    let patientHTMLs: [String]

    var head: some HTML {
        link(.rel(.stylesheet), .href("/mistexamples.css"))
        link(.rel(.stylesheet), .href("/patientmonitor.css"))
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "Live Patient Monitor" }
                p(.class("desc")) { 
                    "A high-stakes demonstration of "
                    span(.class("inline-code")) { "InstanceComponent" }
                    " joining two disparate data sources: "
                    span(.class("inline-code"), .style("color: #909296")) { "Patient Identity" }
                    " (Stable/EMR) and "
                    span(.class("inline-code"), .style("color: #37b24d")) { "Live Vitals" }
                    " (Transient/Telemetry)."
                }
            }

            section(.class("patient-grid")) {
                for html in patientHTMLs {
                    HTMLRaw(html)
                }
            }
            
            footer(.class("mt-4 text-center")) {
                p(.class("desc")) { "Each card is a unified view of two separate database tables joined by a shared UUID." }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
