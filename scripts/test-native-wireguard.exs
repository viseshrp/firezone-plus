# Run only inside a disposable container with NET_ADMIN, never on a live VPN host.
import ExUnit.Assertions

private = Base.decode16!("77076D0A7318A57D3C16C17251B26645DF4C2F87EBC0992AB177FBA51DB92C2A")
expected = Base.decode16!("8520F0098930A754748B7DDCB43EF75A0DBF3A0D26381AF4EBA4A98EAA9B4E6A")
assert {:ok, public} = Wireguardex.get_public_key(Base.encode64(private))
assert Base.decode64!(public) == expected
assert {:error, _} = Wireguardex.get_public_key("invalid-key")

name = "fzcheck#{System.unique_integer([:positive])}"
assert byte_size(name) < 16
assert {:ok, names} = Wireguardex.list_devices()
refute name in names
key = Wireguardex.generate_private_key()
assert {:ok, own_public} = Wireguardex.get_public_key(key)
assert byte_size(Base.decode64!(key)) == 32
psk = Wireguardex.generate_preshared_key()
assert byte_size(Base.decode64!(psk)) == 32

peer = %Wireguardex.PeerConfig{
  public_key: public,
  preshared_key: psk,
  endpoint: "127.0.0.1:51821",
  persistent_keepalive_interval: 15,
  allowed_ips: ["192.0.2.2/32", "2001:db8::2/128"]
}

try do
  assert :ok =
           Wireguardex.set_device(
             %Wireguardex.DeviceConfig{
               private_key: key,
               listen_port: 51831,
               fwmark: 1234,
               peers: [peer],
               replace_peers: true
             },
             name
           )

  assert {:ok, device} = Wireguardex.get_device(name)
  assert device.public_key == own_public
  assert device.fwmark == 1234
  assert device.listen_port == 51831
  assert [actual] = device.peers
  assert actual.config.public_key == public
  assert actual.config.preshared_key == psk
  assert Enum.sort(actual.config.allowed_ips) == Enum.sort(peer.allowed_ips)
  assert actual.config.endpoint == peer.endpoint
  assert actual.config.persistent_keepalive_interval == 15
  assert :ok = Wireguardex.remove_peer(name, public)
  assert {:ok, %{peers: []}} = Wireguardex.get_device(name)
  assert :ok = Wireguardex.add_peer(name, peer)
  assert {:ok, %{peers: [_]}} = Wireguardex.get_device(name)
after
  assert :ok = Wireguardex.delete_device(name)
end

assert {:ok, names} = Wireguardex.list_devices()
refute name in names
IO.puts("Native WireGuard key vectors and kernel interface/peer lifecycle passed")
