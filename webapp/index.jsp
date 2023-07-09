<%@ page pageEncoding="UTF-8" %>
<%@ taglib uri="http://www.springframework.org/tags" prefix="spring" %>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title><spring:message code="root.title" text="Shibboleth IdP" /></title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
  </head>

  <body>
           
        <header> 

          <img src="images/logo.jpg" alt="something went wrong !! " />
          
        </header>

    
        <div class="main">
        
           <div>
    
             <h3><spring:message code="root.message" text="No services are available at this location." /></h3>
   
           </div>
       
         </div>
      

         <footer>
            <div>
                 <h4> Copyright <span id="currentYear"></span> CNRST. All Rights Reserved. </h4>
            </div>
        </footer>
    
    
  <script src="js/script.js"></script>
  </body>
</html>
