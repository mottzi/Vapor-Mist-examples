import Vapor
import Fluent
import Leaf
import Mist

struct DeploymentManager: JSClassConvertible
{
    var jsString: String 
    {
        """
        class \(self.className) 
        {

        }
        """
    }
}

protocol JSClassConvertible 
{
    var className: String { get }
    var jsString: String { get }
}

extension JSClassConvertible 
{
    var className: String { String(describing: Self.self) }
}

