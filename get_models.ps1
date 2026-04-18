$response = Invoke-RestMethod -Uri "https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyBWkdpj8EJVGHOUqJ9k2BRJJ7otwj4EpY0"
$response.models | Select-Object name | Where-Object { $_.name -like '*flash*' } | Select-Object name
