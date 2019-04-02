import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource, MatSort, MatDialog } from '@angular/material';
import { ExpensesService } from '../services/expense.service';
import { UtilityService } from '../services/utility.service';
import { Expense } from '../models/expense.model';
import { CategoriesService } from '../services/categories.service';
import { PaymentMethodsService } from '../services/payment-methods.service';
import { Category } from '../models/category.model';
import { PaymentMethod } from '../models/payment-method.model';
import { ExpenseComponent } from '../expense/expense.component';

@Component({
  selector: 'app-expenses',
  templateUrl: './expenses.component.html',
  styleUrls: ['./expenses.component.scss']
})
export class ExpensesComponent implements OnInit {
  displayedColumns: string[] = ['day', 'category.description', 'description', 'value', 'paymentMethod.description', 'edit', 'remove'];
  dataSource: MatTableDataSource<Expense>;
  @ViewChild(MatSort) sort: MatSort;

  expenses: Expense[];
  categories: Category[];
  paymentMethods: PaymentMethod[];

  constructor(
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService,
    private paymentMethodsService: PaymentMethodsService,
    private dialog: MatDialog) { }

  ngOnInit() {
    this.getExpenses();
  }

  nestedFilterCheck(search, data, key) {
    if (typeof data[key] === 'object') {
      for (const k in data[key]) {
        if (data[key][k] !== null) {
          search = this.nestedFilterCheck(search, data[key], k);
        }
      }
    } else {
      search += data[key];
    }
    return search;
  }

  applyFilter(filterValue: string) {
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  getExpenses() {
    this.util.showLoading();

    const expenses = this.expensesService.getAllFromUser();
    const categories = this.categoriesService.getAllFromUser();
    const payments = this.paymentMethodsService.getAllFromUser();

    expenses.subscribe(data => { this.expenses = data; this.fillDataSource(); });
    categories.subscribe(data => { this.categories = data; this.fillDataSource(); });
    payments.subscribe(data => { this.paymentMethods = data; this.fillDataSource(); });
  }

  fillDataSource() {
    if (this.expenses == null
      || this.categories == null
      || this.paymentMethods == null) {
      return;
    }

    this.expenses.forEach(expense => {
      expense.category = this.categories.find(x => x.id == expense.idCategory);
      expense.paymentMethod = this.paymentMethods.find(x => x.id == expense.idPaymentMethod);
    })

    this.dataSource = new MatTableDataSource(this.expenses);
    this.dataSource.sort = this.sort;

    this.dataSource.filterPredicate = (data, filter: string) => {
      const accumulator = (currentTerm, key) => {
        return this.nestedFilterCheck(currentTerm, data, key);
      };
      const dataStr = Object.keys(data).reduce(accumulator, '').toLowerCase();
      // Transform the filter by converting it to lowercase and removing whitespace.
      const transformedFilter = filter.trim().toLowerCase();
      return dataStr.indexOf(transformedFilter) !== -1;
    };

    this.util.hideLoading();
  }

  getTotalCost() {
    if (this.expenses != null) {
      return this.expenses.map(t => t.value).reduce((acc, value) => acc + value, 0);
    }

    return '';
  }

  getCategory(idCategory: string) {
    return this.categoriesService.get(idCategory).subscribe(data => {
      return data;
    });
  }

  newExpense() {
    const dialogRef = this.dialog.open(ExpenseComponent, {
      width: '550px'
    });

    dialogRef.afterClosed().subscribe(result => {
      console.log('The dialog was closed');
    });
  }

  editExpense(id: string) {
    const dialogRef = this.dialog.open(ExpenseComponent, {
      width: '550px',
      data: id
    });

    dialogRef.afterClosed().subscribe(result => {
      console.log('The dialog was closed');
    });
  }

  removeExpense(id: string) {
    this.util.showLoading();
    this.expensesService
      .remove(id)
      .catch(() => {
      })
      .finally(() => {
        this.util.hideLoading();
      });
  }
}
