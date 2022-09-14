
import glfw::common

pub fn WinMain() {  
    
    if(int r = glfwInit(); r) {
        
        int major;  // 3
        int minor;  // 2
        int rev;    // 1
        glfwGetVersion(&major, &minor, &rev)
        
        var str = glfwGetVersionString()
        
        if(var window = glfwCreateWindow(640, 480, "Hello World".cstr(), null, null); window) {

            loop( ; not glfwWindowShouldClose(window); ) {

                glfwPollEvents();
            } 
            
            glfwDestroyWindow(window)      
        }
        glfwTerminate() 
    }
}

