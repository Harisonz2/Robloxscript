local Players = game:GetService("Players")


local function speedUpNPC(model)
	if model:IsA("Model") and model:FindFirstChild("Humanoid") then
		
		local isPlayer = Players:GetPlayerFromCharacter(model)
		
		if not isPlayer then
			
			model.Humanoid.WalkSpeed = 32
		end
	end
end


for _, object in pairs(workspace:GetDescendants()) do
	speedUpNPC(object)
end


workspace.DescendantAdded:Connect(function(object)
	
	task.wait(0.1) 
	speedUpNPC(object)
end)
