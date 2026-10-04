# Water Physics Shaders

![Static Badge](https://img.shields.io/badge/Water%20Physics%20Shaders-MIT-greem)

## 🌟 Highlights

- Some functionality made easy!
- This problem handled
- etc.


## ℹ️ Overview

For my shader, it implements motion blur, tinting, and cross-blur to modify objects behind it such as the background and player. Specifically for the motion blur, I needed to learn how to get velocity from a gd file and export it to the shader file for use. 

Additionally, I also let the objects interact with the water body to change the shape of waves, having a white spline connecting the top portion to make it look smooth. The top part of the waterbody is made by nodes applying Hooke's Law with the polygon shaped formed through code. Moreover, the water body also an area2d where it emits water particles for objects leaving and entering it. The file is also a tool so you can view the shaders without running the project!

The final thing I choose to add was log that floats to the surface, changing its orientation based on player position on the log. Applying the laws of angular mechanics, the further the player stood from the center of the log, the stronger the torque became, making one side sink significantly more than if it was in the center. the player leaving the log would make it wobble into it come to a equilibrium from the buoyant force and gravity.


### ✍️ Author

I'm [Colin Thai](https://github.io), I always wanted to work to introduce myself to shaders and water related physics as a whole, so I designed and program this project to explore those topics. This repo is a showcase on what I learnt and neat things I figured out

## ⬇️ Installation

Simply have Godot 4.3 installed and clone the repo to see the project in action!

```bash
git clone https://github.com/totallyacoolguy/Water-Physics-Shaders.git
```

As a note, the program runs on the main node so make your changes there to see the effects.
