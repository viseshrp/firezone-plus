defmodule FzHttp.SecurityDependenciesTest do
  use ExUnit.Case, async: false

  defmodule HashField do
    use Cloak.Ecto.PBKDF2, otp_app: :fz_http
  end

  setup do
    previous = Application.fetch_env(:fz_http, HashField)

    on_exit(fn ->
      case previous do
        {:ok, config} -> Application.put_env(:fz_http, HashField, config)
        :error -> Application.delete_env(:fz_http, HashField)
      end
    end)

    :ok
  end

  test "unauthenticated CTR implementations are absent and the vault uses GCM" do
    refute Code.ensure_loaded?(Cloak.Ciphers.AES.CTR)
    refute Code.ensure_loaded?(Cloak.Ciphers.Deprecated.AES.CTR)

    ciphers = Application.fetch_env!(:fz_http, FzHttp.Vault)[:ciphers]
    assert Enum.all?(ciphers, fn {_name, {cipher, _opts}} -> cipher == Cloak.Ciphers.AES.GCM end)
  end

  test "the existing Cloak AES-GCM storage format remains readable" do
    # Fixed key/IV test fixture in the original 1.1.4 envelope format.
    encrypted =
      Base.decode64!(
        "AQpBRVMuR0NNLlYxAAAAAAAAAAAAAAAA7Y779ystzUlgX+kgsX+chavfKU45CQUJKj2gsMiW6Q=="
      )

    opts = [key: <<0::256>>, tag: "AES.GCM.V1", iv_length: 12]
    assert {:ok, "existing-secret"} = Cloak.Ciphers.AES.GCM.decrypt(encrypted, opts)
  end

  test "GCM rejects forged IV, authentication tag, and ciphertext bytes" do
    opts = [key: <<0::256>>, tag: "AES.GCM.V1", iv_length: 12]
    assert {:ok, encrypted} = Cloak.Ciphers.AES.GCM.encrypt("existing-secret", opts)
    assert {:ok, another} = Cloak.Ciphers.AES.GCM.encrypt("existing-secret", opts)
    refute encrypted == another

    # The two-byte header and ten-byte key tag precede the IV.
    for offset <- [12, 24, byte_size(encrypted) - 1] do
      <<prefix::binary-size(^offset), byte, suffix::binary>> = encrypted
      forged = prefix <> <<Bitwise.bxor(byte, 1)>> <> suffix
      assert :error = Cloak.Ciphers.AES.GCM.decrypt(forged, opts)
    end
  end

  test "PBKDF2 honors the iteration count and key length using known SHA-256 vectors" do
    for {iterations, expected} <- [
          {1, "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b"},
          {2, "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43"},
          {600_000, "669cfe52482116fda1aa2cbe409b2f56c8e4563752b7a28f6eaab614ee005178"}
        ] do
      Application.put_env(:fz_http, HashField,
        secret: "salt",
        iterations: iterations,
        size: 32
      )

      assert {:ok, actual} = HashField.dump("password")
      assert Base.encode16(actual, case: :lower) == expected
    end

    Application.put_env(:fz_http, HashField, secret: "salt", iterations: 2, size: 16)
    assert {:ok, shorter} = HashField.dump("password")
    assert Base.encode16(shorter, case: :lower) == "ae4d0c95af6b46d32d0adff928f06dd0"
    assert {:ok, nil} = HashField.dump(nil)
  end

  test "PBKDF2 rejects an invalid iteration count" do
    Application.put_env(:fz_http, HashField, secret: "salt", iterations: 0, size: 32)
    assert_raise Cloak.InvalidConfig, fn -> HashField.dump("password") end
  end

  test "structured headers reject every non-printable ASCII and non-ASCII byte" do
    for byte <- Enum.to_list(0..31) ++ Enum.to_list(127..255) do
      value = {:item, {:string, <<"safe", byte, "value">>}, []}
      assert catch_error(:cow_http_struct_hd.item(value)) == :function_clause
    end

    value = {:item, {:string, ~s(safe "quoted" \\ value)}, []}
    encoded = value |> :cow_http_struct_hd.item() |> IO.iodata_to_binary()
    assert :cow_http_struct_hd.parse_item(encoded) == value
  end
end
