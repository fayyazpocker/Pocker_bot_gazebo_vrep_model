-- Bot configuration
wheel_diameter = 0.087014

-- Robot handles
robotHandle = sim.getObjectHandle('pocker_bot_base_link')
motorLeft=sim.getObjectHandle('joint_left_wheel_link')
motorRight=sim.getObjectHandle('joint_right_wheel_link')
odomhandle = sim.getObjectHandle('Odom')
base_link_handle = sim.getObjectHandle('Base_link')
laser = sim.getObjectHandle('Hokuyo')

--Publishers
odom_publisher = simROS.advertise('/odom','nav_msgs/Odometry')

-- TF frames
tf_map2odom = false -- make it false if you dont want map to odom transform
tf_odom2base = false -- make it false if you dont want odom to base transform

map_frame = "map"
odom_frame = "odom"
base_frame = "base_link"
left_wheel_link_name = "left_wheel_link"
right_wheel_link_name = "right_wheel_link"
laser_link_name = "laser_frame"

--function to set the target velocity of wheels
function set_wheel_target_velocity(left_vel,right_vel)
    sim.setJointTargetVelocity(motorLeft,left_vel)
    sim.setJointTargetVelocity(motorRight,right_vel)
    sim.addStatusbarMessage(string.format("left_vel:%f right_vel:%f",left_vel, right_vel))
end

--function to convert cmd_vel to target velocities
function cmd_callback(msg) 
    vel = msg.linear.x
    ang = msg.angular.z
    left_vel = vel + (wheel_diameter)*ang
    right_vel = vel - (wheel_diameter)*ang

    set_wheel_target_velocity(left_vel,right_vel)
end

--Function to get transform of a child frame from a parent frame
-- objHandle is the object handle about which we want transform, name is the frame id we are publishing, 
-- relTo : -1 if world or object handle, relToName is the world if relative to world or base_link if relative to robot
function getTransformStamped(child_handle,child_frame,parent_handle,parent_frame)
    t=sim.getSystemTime()
    p=sim.getObjectPosition(child_handle,parent_handle)
    o=sim.getObjectQuaternion(child_handle,parent_handle)
    return {
        header={
            stamp=t,
            frame_id=parent_frame
        },
        child_frame_id=child_frame,
        transform={
            translation={x=p[1],y=p[2],z=p[3]},
            rotation={x=o[1],y=o[2],z=o[3],w=o[4]}
        }
    }
end

--Function to send transform of pocker_bot
function send_transforms()

    transforms = {}
    if tf_map2odom then
        table.insert(transforms,getTransformStamped(odomhandle,odom_frame,-1,map_frame)) --map --> odom
        -- print("hi")
    end

    if tf_odom2base then
        table.insert(transforms,getTransformStamped(robotHandle,base_frame,odomhandle,odom_frame)) -- odom --> base_frame
    end

    table.insert(transforms,getTransformStamped(motorLeft,left_wheel_link_name,base_link_handle,base_frame)) -- base_frame --> left_wheel_link
    table.insert(transforms,getTransformStamped(motorRight,right_wheel_link_name,base_link_handle,base_frame))
    -- print (transforms)
    table.insert(transforms,getTransformStamped(laser,laser_link_name,base_link_handle,base_frame))

    simROS.sendTransforms(transforms)
end

--Function to publish odom as nav_msgs/Odometry
function publish_odom()

    tf_odom=getTransformStamped(base_link_handle,base_frame,odomhandle,odom_frame) --odom --> base_frame
    linearVelocity, angularVelocity= sim.getObjectVelocity(base_link_handle)
    t=sim.getSystemTime()

    odom = 
    {
        header=
        {
            stamp= t,
            frame_id= odom_frame
        },
        child_frame_id= base_frame,
        pose=   
        {
            pose=  --use tf information
            {
                position= {x=tf_odom.transform.translation.x, y=tf_odom.transform.translation.y, z=tf_odom.transform.translation.z},
                orientation= {x=tf_odom.transform.rotation.x, y=tf_odom.transform.rotation.y, z=tf_odom.transform.rotation.z, w=tf_odom.transform.rotation.w}
            }
        },
        twist=
        {
            twist=
            {
                linear= {x=linearVelocity[1], y=linearVelocity[2], z=linearVelocity[3]},
                angular= {x=angularVelocity[1], y=angularVelocity[2], z=angularVelocity[3]}
            }
        }
    }

    simROS.publish(odom_publisher,odom)
end

function set_pose_callback(msg)
    sim.resetDynamicObject(sim.handle_all)
    sim.setObjectPosition(robotHandle,-1,{msg.x,msg.y,(wheel_diameter/2)})
    sim.setObjectOrientation(robotHandle,-1,{0,0,msg.theta})
    sim.setObjectPosition(odomhandle,robotHandle,{0,0,0})
    sim.setObjectOrientation(odomhandle,robotHandle,{0,0,0})
    sim.resetDynamicObject(sim.handle_all)
    -- return true
end


if (sim_call_type==sim.syscb_init) then 

    local moduleName=0
    local moduleVersion=0
    local index=0
    local pluginNotFound=true
    while moduleName do
        moduleName,moduleVersion=sim.getModuleName(index)
        if (moduleName=='RosInterface') then
            pluginNotFound=false
        end
        index=index+1
    end
    if (pluginNotFound) then
        -- Display an error message if the plugin was not found:
        sim.displayDialog('Error','RosInterface plugin not found. Run roscore before launching V-REP',sim.dlgstyle_ok,false,nil,{0.8,0,0,0,0,0},{0.5,0,0,1,1,1})
    end

-- Detaching the odom dummy for odom frame and setting the dummy at the same position as the robot at a height at the radius of the wheel
    sim.setObjectParent(odomhandle,-1,true)
    sim.setObjectPosition(odomhandle,base_link_handle,{0,0,0})
    odom_pos = sim.getObjectPosition(odomhandle,-1)
    sim.setObjectPosition(odomhandle,-1,{odom_pos[1],odom_pos[2],0}) -- base_link must be at the ground

-- Enable topic subscription:
    cmd_vel_sub = simROS.subscribe('/cmd_vel','geometry_msgs/Twist','cmd_callback')
    set_pose_sub = simROS.subscribe('/reset_pocker_bot','geometry_msgs/Pose2D','set_pose_callback')
end 


if (sim_call_type==sim.syscb_cleanup) then
    simROS.shutdownSubscriber(cmd_vel_sub)
    simROS.shutdownPublisher(odom_publisher) 
end 

if (sim_call_type==sim.syscb_actuation) then
    
    -- Send the robot's transform:
    send_transforms()
    publish_odom()

end 

