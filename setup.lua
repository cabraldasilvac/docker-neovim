return {
	"seu-user/docker-neovim",
	config = function()
		require("docker").setup()
	end,
	lazy = false,
}
