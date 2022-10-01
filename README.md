
# personal-dashboard
### About the site
This is a personal project with the primary goal of illustrating my ability to build a 
full stack web application. It has a frontend, a backend, a database and communicates 
with third party APIs. If you can find it in your heart, please focus on the backend, 
deployment and hosting sections while leaving the frontend alone. 
### Backend
##### Features
- Interacts with the Google Calendar API via Oauth2
- Web scrapes Project Euler and sends the HTML captured back to the frontend to display
- Acts as a proxy for the frontend to talk to CockRoach DB enabling creation and deletion 
of activities
##### Challenges
- I had never done Oauth before and my token keeps getting revoked. This is something
I am still learning about and is a work in progress.

### Frontend
##### Preface
The frontend for this website is writtend 100% in Elm which then compiles to Javascript.
I do not enjoy building frontends but Elm eased the pain greatly. I am very passionate
about functional programming and Elm let me write my least favourite part of the stack
in a beautiful language. Please keep in mind that the primary focus of the project is to
showcase my ability to scrape together, deploy and host a full stack web app.
##### Features
- Very fast as it is essentially raw Javascript (compiled from Elm)
- Talks to the backend over HTTP making GET and POST requests
- Displays the data coming from the backend
- Ugly ugly ugly (sorry I am a backend dev)

### Hosting
A Raspberry Pi running Nginx is where everything except for the database is hosted. Is it 
dangerous? Maybe but worth the learning experience for me :)
##### Challenges
- There is no way to compile elm on an arm processor so compilation must happen with a
pre-commit hook. 
- Since the Elm code is compiled to Javascript before deployment, we cannot store the 
url for the backend in the Elm code. If we did, it would be impossible to have dev and prod
environments.To solve this problem, index.html file is generated in the initialization 
of the backend. This enables a url flag to be dynamically set based on an environment 
variable.
- I am still failing my SSL cert but not giving up yet
- Logging is not figured out yet and desperately needs to be implemented
### Deployment
Deployment was the most fun part of this project. I am listening for GitHub actions on the 
Raspberry Pi. On push to main, deployment steps run. Super happy to have a CI/CD pipline 
running that is hand rolled.
