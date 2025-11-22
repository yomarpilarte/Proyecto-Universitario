
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.IO;


namespace Viajes.Models.Helpers
{
    public static class Conexion
    {
        private static readonly string _cadenaConexion;

        static Conexion()
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json");

            var config = builder.Build();
            _cadenaConexion = config.GetConnectionString("DefaultConnection");
        }

        public static SqlConnection ObtenerConexion()
        {
            return new SqlConnection(_cadenaConexion);
        }

    }
}
