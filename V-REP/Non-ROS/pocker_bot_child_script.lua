-- Controlling bot to test
if (sim_call_type==sim.syscb_init) then 
    motorLeft=sim.getObjectHandle('joint_left_wheel_link')
    motorRight=sim.getObjectHandle('joint_right_wheel_link')
    
    vLeft=0
    vRight=0
end 

if (sim_call_type==sim.syscb_cleanup) then 
 
end 

if (sim_call_type==sim.syscb_actuation) then 
    --while sim.getSimulationState()~=sim.simulation_advancing_abouttostop do
        -- Read the keyboard messages (make sure the focus is on the main window, scene view):
        message,auxiliaryData=sim.getSimulatorMessage()
        while message~=-1 do
            if (message==sim.message_keypress) then
                if (auxiliaryData[1]==2007) then
                    -- up key
                    vLeft=0.5
                    vRight=0.5
                end
                if (auxiliaryData[1]==2008) then
                    -- down key
                     vLeft=-0.5
                    vRight=-0.5
                end
                if (auxiliaryData[1]==2009) then
                    -- left key
                   vLeft=-0.5
                    vRight=0.5 
                end
                if (auxiliaryData[1]==2010) then
                    -- right key
                    vLeft=0.5
                    vRight=-0.5
                end
                if (auxiliaryData[1]==105) then
                    -- right key
                    vLeft=vLeft+0.1
                    vRight=vRight+0.1
                end
                if (auxiliaryData[1]==100) then
                    -- right key
                    vLeft=vLeft-0.1
                    vRight=vRight-0.1
                end
                if (auxiliaryData[1]==115) then
                    -- right key
                    vLeft=0
                    vRight=0
                end
                sim.addStatusbarMessage('you typed:'..auxiliaryData[1])
            end
            message,auxiliaryData=sim.getSimulatorMessage()
        end
    --end
    sim.setJointTargetVelocity(motorLeft,vLeft)
    sim.setJointTargetVelocity(motorRight,vRight)
end 